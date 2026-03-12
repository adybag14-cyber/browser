const lp = @import("lightpanda");
const std = @import("std");
const builtin = @import("builtin");
const js = @import("../../../js/js.zig");
const Factory = @import("../../../Factory.zig");
const Frame = @import("../../../Frame.zig");
const Node = @import("../../Node.zig");
const Element = @import("../../Element.zig");
const HtmlElement = @import("../Html.zig");

const Image = @This();

pub const Proto = HtmlElement;
_pad: bool = false,
_proto_canary: if (lp.IS_DEBUG) *HtmlElement else void = undefined,

pub fn constructor(w_: ?u32, h_: ?u32, frame: *Frame) !*Image {
    const node = try Frame.node_factory.createElementNS(frame, .html, "img", null);
    const el = node.as(Element);

    if (w_) |w| blk: {
        const w_string = std.fmt.bufPrint(&frame.buf, "{d}", .{w}) catch break :blk;
        try el.setAttributeSafe(comptime .wrap("width"), .wrap(w_string), frame);
    }
    if (h_) |h| blk: {
        const h_string = std.fmt.bufPrint(&frame.buf, "{d}", .{h}) catch break :blk;
        try el.setAttributeSafe(comptime .wrap("height"), .wrap(h_string), frame);
    }
    return el.as(Image);
}

pub fn asElement(self: *Image) *Element {
    return Factory.protoOf(self).asElement();
}
pub fn asConstElement(self: *const Image) *const Element {
    return Factory.protoOf(self).asElement();
}
pub fn asNode(self: *Image) *Node {
    return self.asElement().asNode();
}

pub fn getSrc(self: *const Image, frame: *Frame) ![]const u8 {
    const element = self.asConstElement();
    const src = element.getAttributeSafe(comptime .wrap("src")) orelse return "";
    if (src.len == 0) {
        return "";
    }
    return element.asConstNode().resolveURLReflect(src, frame, .{});
}

pub fn setSrc(self: *Image, value: []const u8, frame: *Frame) !void {
    const element = self.asElement();
    try element.setAttributeSafe(comptime .wrap("src"), .wrap(value), frame);
    // No need to check if `Image` is connected to DOM; this is a special case.
    return self.imageAddedCallback(frame);
}

pub fn getLoading(self: *const Image) []const u8 {
    return self.asConstElement().getAttributeSafe(comptime .wrap("loading")) orelse "eager";
}

pub fn setLoading(self: *Image, value: []const u8, frame: *Frame) !void {
    try self.asElement().setAttributeSafe(comptime .wrap("loading"), .wrap(value), frame);
}

pub fn getNaturalWidth(self: *Image, page: *Page) u32 {
    _ = self.getCanvasSurface(page);
    return self._natural_width;
}

pub fn getNaturalHeight(self: *Image, page: *Page) u32 {
    _ = self.getCanvasSurface(page);
    return self._natural_height;
}

pub fn getComplete(_: *const Image) bool {
    // Per spec, complete is true when: no src/srcset, src is empty,
    // image is fully available, or image is broken (with no pending request).
    // Since we never fetch images, they are in the "broken" state, which has
    // complete=true. This is consistent with naturalWidth/naturalHeight=0.
    return true;
}

/// Used in `Page.nodeIsReady`.
pub fn imageAddedCallback(self: *Image, frame: *Frame) !void {
    // if we're planning on navigating to another frame, don't trigger load event.
    if (frame.isGoingAway()) {
        return;
    }

    const element = self.asElement();
    // Exit if src not set.
    const src = element.getAttributeSafe(comptime .wrap("src")) orelse return;
    if (src.len == 0) return;

    try frame.queueLoad(Factory.protoOf(self));
}

pub fn getCanvasSurface(self: *Image, page: *Page) ?*const CanvasSurface {
    if (self._surface) |surface| {
        return surface;
    }
    if (self._surface_load_attempted and self._surface_load_failed) {
        return null;
    }

    self._surface_load_attempted = true;
    self.loadCanvasSurface(page) catch |err| {
        self._surface_load_failed = true;
        log.debug(.page, "image decode failed", .{ .err = err, .url = self.getSrc(page) catch "" });
        return null;
    };
    return self._surface;
}

fn loadCanvasSurface(self: *Image, page: *Page) !void {
    const src = try self.getSrc(page);
    if (src.len == 0) {
        self._surface_load_failed = true;
        return;
    }

    const include_credentials = imageRequestAttributeIncludesCredentials(self.getCrossOrigin());
    var arena = std.heap.ArenaAllocator.init(page.arena);
    defer arena.deinit();
    const temp = arena.allocator();

    var temporary_path: ?[]u8 = null;
    defer if (temporary_path) |path| {
        if (std.fs.path.isAbsolute(path)) {
            std.fs.deleteFileAbsolute(path) catch {};
        }
        temp.free(path);
    };

    const path = if (std.mem.startsWith(u8, src, "http://") or std.mem.startsWith(u8, src, "https://"))
        blk: {
            const request_url = try imageRequestUrlForFetch(temp, src, include_credentials);
            const bytes = try fetchImageBytes(page, temp, request_url, include_credentials);
            const written = try writeTempImageFile(temp, imageUrlFileExtension(src), bytes);
            temporary_path = written;
            break :blk written;
        }
    else if (std.mem.startsWith(u8, src, "data:"))
        blk: {
            const bytes = try parseDataUriBytes(temp, src);
            const written = try writeTempImageFile(temp, imageUrlFileExtension(src), bytes);
            temporary_path = written;
            break :blk written;
        }
    else if (std.mem.startsWith(u8, src, "file://"))
        try localFilePathFromUrl(temp, src)
    else {
        self._surface_load_failed = true;
        return;
    };

    const decoded = (try decodeImageSurfaceFromFile(page.arena, path)) orelse {
        self._surface_load_failed = true;
        return;
    };

    self._surface = decoded.surface;
    self._natural_width = decoded.width;
    self._natural_height = decoded.height;
    self._surface_load_failed = false;
}

const DecodedImageSurface = struct {
    surface: *CanvasSurface,
    width: u32,
    height: u32,
};

const ImageFetchContext = struct {
    allocator: std.mem.Allocator,
    buffer: std.ArrayList(u8),
    finished: bool = false,
    failed: ?anyerror = null,
    status: u16 = 0,
};

fn fetchImageBytes(
    page: *Page,
    temp: std.mem.Allocator,
    request_url: [:0]const u8,
    include_credentials: bool,
) ![]u8 {
    const client = try page._session.browser.app.http.createClient(temp);
    defer client.deinit();

    var headers = try client.newHeaders();
    try headers.add(IMAGE_ACCEPT_HEADER);
    try page.headersForRequestWithPolicy(page.arena, request_url, &headers, .{
        .include_credentials = include_credentials,
    });

    var ctx = ImageFetchContext{
        .allocator = temp,
        .buffer = .{},
    };
    defer ctx.buffer.deinit(temp);

    try client.request(.{
        .url = request_url,
        .ctx = &ctx,
        .method = .GET,
        .frame_id = page._frame_id,
        .headers = headers,
        .cookie_jar = if (include_credentials) page._session.cookie_jar else null,
        .resource_type = .image,
        .notification = page._session.notification,
        .header_callback = imageFetchHeaderCallback,
        .data_callback = imageFetchDataCallback,
        .done_callback = imageFetchDoneCallback,
        .error_callback = imageFetchErrorCallback,
    });

    while (!ctx.finished and ctx.failed == null) {
        _ = try client.tick(50);
    }
    if (ctx.failed) |err| {
        return err;
    }
    return try temp.dupe(u8, ctx.buffer.items);
}

fn imageFetchHeaderCallback(transfer: *Http.Transfer) !bool {
    const ctx: *ImageFetchContext = @ptrCast(@alignCast(transfer.ctx));
    const response_header = transfer.response_header orelse return true;
    ctx.status = response_header.status;
    if (response_header.status >= 400) {
        ctx.failed = error.BadStatusCode;
    }
    return true;
}

fn imageFetchDataCallback(transfer: *Http.Transfer, data: []const u8) !void {
    const ctx: *ImageFetchContext = @ptrCast(@alignCast(transfer.ctx));
    try ctx.buffer.appendSlice(ctx.allocator, data);
}

fn imageFetchDoneCallback(ctx_ptr: *anyopaque) !void {
    const ctx: *ImageFetchContext = @ptrCast(@alignCast(ctx_ptr));
    ctx.finished = true;
}

fn imageFetchErrorCallback(ctx_ptr: *anyopaque, err: anyerror) void {
    const ctx: *ImageFetchContext = @ptrCast(@alignCast(ctx_ptr));
    ctx.failed = err;
    ctx.finished = true;
}

fn imageRequestAttributeIncludesCredentials(cross_origin: ?[]const u8) bool {
    const value = cross_origin orelse return true;
    return std.ascii.eqlIgnoreCase(std.mem.trim(u8, value, " \t\r\n"), "use-credentials");
}

fn imageRequestUrlForFetch(
    allocator: std.mem.Allocator,
    url: []const u8,
    include_credentials: bool,
) ![:0]const u8 {
    if (include_credentials) {
        return try allocator.dupeZ(u8, url);
    }
    const url_z = try allocator.dupeZ(u8, url);
    if (URL.getUsername(url_z).len == 0) {
        return url_z;
    }
    return try URL.buildUrl(
        allocator,
        URL.getProtocol(url_z),
        URL.getHost(url_z),
        URL.getPathname(url_z),
        URL.getSearch(url_z),
        URL.getHash(url_z),
    );
}

fn imageUrlFileExtension(url: []const u8) []const u8 {
    if (std.mem.indexOfScalar(u8, url, '?')) |query_index| {
        return imageUrlFileExtension(url[0..query_index]);
    }
    if (std.mem.indexOfScalar(u8, url, '#')) |fragment_index| {
        return imageUrlFileExtension(url[0..fragment_index]);
    }
    if (std.mem.startsWith(u8, url, "data:image/")) {
        const tail = url["data:image/".len..];
        const end = std.mem.indexOfAny(u8, tail, ";,") orelse tail.len;
        return tail[0..end];
    }

    const base = std.fs.path.basename(url);
    if (std.mem.lastIndexOfScalar(u8, base, '.')) |dot_index| {
        const ext = base[dot_index + 1 ..];
        if (ext.len > 0 and ext.len <= 8) {
            return ext;
        }
    }
    return "img";
}

fn writeTempImageFile(allocator: std.mem.Allocator, extension: []const u8, bytes: []const u8) ![]u8 {
    const temp_dir = std.process.getEnvVarOwned(allocator, "TEMP") catch try std.process.getEnvVarOwned(allocator, "TMP");
    defer allocator.free(temp_dir);

    const file_name = try std.fmt.allocPrint(allocator, "lightpanda-image-{d}.{s}", .{ std.time.milliTimestamp(), extension });
    defer allocator.free(file_name);

    const path = try std.fs.path.join(allocator, &.{ temp_dir, file_name });
    errdefer allocator.free(path);

    const file = try std.fs.createFileAbsolute(path, .{ .truncate = true });
    defer file.close();
    try file.writeAll(bytes);
    return path;
}

fn localFilePathFromUrl(allocator: std.mem.Allocator, url: []const u8) ![]u8 {
    const after_scheme = url["file://".len..];
    const end = std.mem.indexOfAny(u8, after_scheme, "?#") orelse after_scheme.len;
    var raw_path = after_scheme[0..end];
    if (std.mem.startsWith(u8, raw_path, "localhost/")) {
        raw_path = raw_path["localhost".len..];
    }
    raw_path = std.mem.trimLeft(u8, raw_path, "/");
    const unescaped = try URL.unescape(allocator, raw_path);
    defer if (unescaped.ptr != raw_path.ptr) allocator.free(unescaped);

    const owned = try allocator.dupe(u8, unescaped);
    for (owned) |*ch| {
        if (ch.* == '/') {
            ch.* = '\\';
        }
    }
    return owned;
}

fn parseDataUriBytes(allocator: std.mem.Allocator, src: []const u8) ![]const u8 {
    const uri = src[5..];
    const comma = std.mem.indexOfScalar(u8, uri, ',') orelse return error.InvalidDataUrl;
    const metadata = uri[0..comma];
    const payload = uri[comma + 1 ..];
    const unescaped = try URL.unescape(allocator, payload);
    defer if (unescaped.ptr != payload.ptr) allocator.free(unescaped);
    if (!std.mem.endsWith(u8, metadata, ";base64")) {
        return allocator.dupe(u8, unescaped);
    }

    var stripped = std.ArrayList(u8).empty;
    defer stripped.deinit(allocator);
    for (unescaped) |cch| {
        if (!std.ascii.isWhitespace(cch)) {
            try stripped.append(allocator, cch);
        }
    }
    const trimmed = std.mem.trimRight(u8, stripped.items, "=");
    const decoded_size = std.base64.standard_no_pad.Decoder.calcSizeForSlice(trimmed) catch return error.InvalidDataUrl;
    const decoded = try allocator.alloc(u8, decoded_size);
    _ = std.base64.standard_no_pad.Decoder.decode(decoded, trimmed) catch return error.InvalidDataUrl;
    return decoded;
}

fn decodeImageSurfaceFromFile(allocator: std.mem.Allocator, path: []const u8) !?DecodedImageSurface {
    if (builtin.os.tag != .windows) {
        return null;
    }

    var token: win.ULONG_PTR = 0;
    var input = GdiplusStartupInput{
        .GdiplusVersion = 1,
        .DebugEventCallback = null,
        .SuppressBackgroundThread = 0,
        .SuppressExternalCodecs = 0,
    };
    if (GdiplusStartup(&token, &input, null) != GDIP_STATUS_OK) {
        return null;
    }
    defer GdiplusShutdown(token);

    const wide_path = try std.unicode.utf8ToUtf16LeAllocZ(allocator, path);
    defer allocator.free(wide_path);

    var image: ?*GpImage = null;
    if (GdipLoadImageFromFile(wide_path.ptr, &image) != GDIP_STATUS_OK or image == null) {
        return null;
    }
    defer _ = GdipDisposeImage(image.?);

    var width: win.UINT = 0;
    var height: win.UINT = 0;
    if (GdipGetImageWidth(image.?, &width) != GDIP_STATUS_OK or
        GdipGetImageHeight(image.?, &height) != GDIP_STATUS_OK)
    {
        return null;
    }

    const surface = try CanvasSurface.init(allocator, width, height);
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            var pixel: Argb = 0;
            if (GdipBitmapGetPixel(@ptrCast(image.?), @intCast(x), @intCast(y), &pixel) != GDIP_STATUS_OK) {
                continue;
            }
            surface.setPixel(x, y, .{
                .r = @intCast((pixel >> 16) & 0xff),
                .g = @intCast((pixel >> 8) & 0xff),
                .b = @intCast(pixel & 0xff),
                .a = @intCast((pixel >> 24) & 0xff),
            });
        }
    }

    return .{
        .surface = surface,
        .width = width,
        .height = height,
    };
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(Image);

    pub const Meta = struct {
        pub const name = "HTMLImageElement";
        pub const constructor_alias = "Image";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const constructor = bridge.constructor(Image.constructor, .{});
    pub const src = bridge.accessor(Image.getSrc, Image.setSrc, .{ .ce_reactions = true });
    pub const currentSrc = bridge.accessor(Image.getSrc, null, .{});
    pub const alt = reflect.string("alt");
    pub const width = reflect.unsignedLong("width", .{});
    pub const height = reflect.unsignedLong("height", .{});
    pub const crossOrigin = reflect.enumerated("crossorigin", &.{ "anonymous", "use-credentials" }, .{ .missing = null, .nullable = true, .invalid = "anonymous" });
    pub const loading = bridge.accessor(Image.getLoading, Image.setLoading, .{ .ce_reactions = true });
    const reflect = Element.Reflect(Image);
    pub const srcset = reflect.string("srcset");
    pub const useMap = reflect.string("usemap");
    pub const isMap = reflect.boolean("ismap");
    pub const referrerPolicy = reflect.referrerPolicy();
    pub const decoding = reflect.enumerated("decoding", &.{ "async", "sync", "auto" }, .{ .missing = "auto" });
    // Obsolete
    pub const name = reflect.string("name");
    pub const lowsrc = reflect.url("lowsrc");
    pub const @"align" = reflect.string("align");
    pub const hspace = reflect.unsignedLong("hspace", .{});
    pub const vspace = reflect.unsignedLong("vspace", .{});
    pub const longDesc = reflect.url("longdesc");
    pub const border = reflect.stringNullToEmpty("border");

    pub const naturalWidth = bridge.accessor(Image.getNaturalWidth, null, .{});
    pub const naturalHeight = bridge.accessor(Image.getNaturalHeight, null, .{});
    pub const complete = bridge.accessor(Image.getComplete, null, .{});
};

pub const Build = struct {
    pub fn created(node: *Node, frame: *Frame) !void {
        const self = node.as(Image);
        return self.imageAddedCallback(frame);
    }
};

const testing = @import("../../../../testing.zig");
test "WebApi: HTML.Image" {
    try testing.htmlRunner("element/html/image.html", .{});
}
