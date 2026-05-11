// Copyright (C) 2023-2026  Lightpanda (Selecy SAS)
//
// Francis Bouvier <francis@lightpanda.io>
// Pierre Tachoire <pierre@lightpanda.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const libcurl = @import("sys/libcurl.zig");

const log = @import("log.zig");
const Config = @import("Config.zig");
const assert = @import("lightpanda").assert;

pub const ENABLE_DEBUG = false;
const IS_DEBUG = builtin.mode == .Debug;
pub const DISABLED_PROXY: [:0]const u8 = "";
const LOOPBACK_NO_PROXY: [:0]const u8 = "localhost,127.0.0.1,::1,[::1]";

pub const Blob = libcurl.CurlBlob;
pub const WaitFd = libcurl.CurlWaitFd;
pub const writefunc_error = libcurl.curl_writefunc_error;

const Error = libcurl.Error;
const ErrorMulti = libcurl.ErrorMulti;
const errorFromCode = libcurl.errorFromCode;
const errorMFromCode = libcurl.errorMFromCode;
const errorCheck = libcurl.errorCheck;
const errorMCheck = libcurl.errorMCheck;

pub fn curl_version() [*c]const u8 {
    return libcurl.curl_version();
}

pub const Method = enum(u8) {
    GET = 0,
    PUT = 1,
    POST = 2,
    DELETE = 3,
    HEAD = 4,
    OPTIONS = 5,
    PATCH = 6,
    PROPFIND = 7,
};

pub const Header = struct {
    name: []const u8,
    value: []const u8,
};

pub const Headers = struct {
    headers: ?*libcurl.CurlSList,
    cookies: ?[*c]const u8,

    pub fn init(user_agent: [:0]const u8) !Headers {
        const header_list = libcurl.curl_slist_append(null, user_agent);
        if (header_list == null) {
            return error.OutOfMemory;
        }
        return .{ .headers = header_list, .cookies = null };
    }

    pub fn deinit(self: *const Headers) void {
        if (self.headers) |hdr| {
            libcurl.curl_slist_free_all(hdr);
        }
    }

    pub fn add(self: *Headers, header: [*c]const u8) !void {
        // Copies the value
        const updated_headers = libcurl.curl_slist_append(self.headers, header);
        if (updated_headers == null) {
            return error.OutOfMemory;
        }

        self.headers = updated_headers;
    }

    fn parseHeader(header_str: []const u8) ?Header {
        const colon_pos = std.mem.indexOfScalar(u8, header_str, ':') orelse return null;

        const name = std.mem.trim(u8, header_str[0..colon_pos], " \t");
        const value = std.mem.trim(u8, header_str[colon_pos + 1 ..], " \t");

        return .{ .name = name, .value = value };
    }

    pub fn iterator(self: *Headers) Iterator {
        return .{
            .header = self.headers,
            .cookies = self.cookies,
        };
    }

    const Iterator = struct {
        header: [*c]libcurl.CurlSList,
        cookies: ?[*c]const u8,

        pub fn next(self: *Iterator) ?Header {
            const h = self.header orelse {
                const cookies = self.cookies orelse return null;
                self.cookies = null;
                return .{ .name = "Cookie", .value = std.mem.span(@as([*:0]const u8, cookies)) };
            };

            self.header = h.*.next;
            return parseHeader(std.mem.span(@as([*:0]const u8, @ptrCast(h.*.data))));
        }
    };
};

// In normal cases, the header iterator comes from the curl linked list.
// But it's also possible to inject a response, via `transfer.fulfill`. In that
// case, the resposne headers are a list, []const Http.Header.
// This union, is an iterator that exposes the same API for either case.
pub const HeaderIterator = union(enum) {
    curl: CurlHeaderIterator,
    list: ListHeaderIterator,

    pub fn next(self: *HeaderIterator) ?Header {
        switch (self.*) {
            inline else => |*it| return it.next(),
        }
    }

    const CurlHeaderIterator = struct {
        conn: *const Connection,
        prev: ?*libcurl.CurlHeader = null,

        pub fn next(self: *CurlHeaderIterator) ?Header {
            const h = libcurl.curl_easy_nextheader(self.conn.easy, .header, -1, self.prev) orelse return null;
            self.prev = h;

            const header = h.*;
            return .{
                .name = std.mem.span(header.name),
                .value = std.mem.span(header.value),
            };
        }
    };

    const ListHeaderIterator = struct {
        index: usize = 0,
        list: []const Header,

        pub fn next(self: *ListHeaderIterator) ?Header {
            const idx = self.index;
            if (idx == self.list.len) {
                return null;
            }
            self.index = idx + 1;
            return self.list[idx];
        }
    };
};

const HeaderValue = struct {
    value: []const u8,
    amount: usize,
};

pub const AuthChallenge = struct {
    status: u16,
    source: ?enum { server, proxy },
    scheme: ?enum { basic, digest },
    realm: ?[]const u8,

    pub fn parse(status: u16, header: []const u8) !AuthChallenge {
        var ac: AuthChallenge = .{
            .status = status,
            .source = null,
            .realm = null,
            .scheme = null,
        };

        const sep = std.mem.indexOfPos(u8, header, 0, ": ") orelse return error.InvalidHeader;
        const hname = header[0..sep];
        const hvalue = header[sep + 2 ..];

        if (std.ascii.eqlIgnoreCase("WWW-Authenticate", hname)) {
            ac.source = .server;
        } else if (std.ascii.eqlIgnoreCase("Proxy-Authenticate", hname)) {
            ac.source = .proxy;
        } else {
            return error.InvalidAuthChallenge;
        }

        const pos = std.mem.indexOfPos(u8, std.mem.trim(u8, hvalue, std.ascii.whitespace[0..]), 0, " ") orelse hvalue.len;
        const _scheme = hvalue[0..pos];
        if (std.ascii.eqlIgnoreCase(_scheme, "basic")) {
            ac.scheme = .basic;
        } else if (std.ascii.eqlIgnoreCase(_scheme, "digest")) {
            ac.scheme = .digest;
        } else {
            return error.UnknownAuthChallengeScheme;
        }

        return ac;
    }
};

pub const ResponseHead = struct {
    pub const MAX_CONTENT_TYPE_LEN = 64;

    status: u16,
    url: [*c]const u8,
    redirect_count: u32,
    _content_type_len: usize = 0,
    _content_type: [MAX_CONTENT_TYPE_LEN]u8 = undefined,
    // this is normally an empty list, but if the response is being injected
    // than it'll be populated. It isn't meant to be used directly, but should
    // be used through the transfer.responseHeaderIterator() which abstracts
    // whether the headers are from a live curl easy handle, or injected.
    _injected_headers: []const Header = &.{},

    pub fn contentType(self: *ResponseHead) ?[]u8 {
        if (self._content_type_len == 0) {
            return null;
        }
        return self._content_type[0..self._content_type_len];
    }
};

pub fn globalInit() Error!void {
    try libcurl.curl_global_init(.{
        .ssl = true,
        .win32 = builtin.os.tag == .windows,
    });
}

pub fn globalDeinit() void {
    libcurl.curl_global_cleanup();
}

pub const Connection = struct {
    easy: *libcurl.Curl,
    node: Handles.HandleList.Node = .{},

    pub fn init(
        ca_blob_: ?libcurl.CurlBlob,
        config: *const Config,
    ) !Connection {
        const easy = libcurl.curl_easy_init() orelse return error.FailedToInitializeEasy;
        errdefer libcurl.curl_easy_cleanup(easy);

        // timeouts
        try libcurl.curl_easy_setopt(easy, .timeout_ms, config.httpTimeout());
        try libcurl.curl_easy_setopt(easy, .connect_timeout_ms, config.httpConnectTimeout());

        // redirect behavior
        try libcurl.curl_easy_setopt(easy, .max_redirs, config.httpMaxRedirects());
        try libcurl.curl_easy_setopt(easy, .follow_location, 2);
        try libcurl.curl_easy_setopt(easy, .redir_protocols_str, "HTTP,HTTPS"); // remove FTP and FTPS from the default

        // proxy
        const http_proxy = config.httpProxy();
        if (http_proxy) |proxy| {
            try libcurl.curl_easy_setopt(easy, .proxy, proxy.ptr);
        } else {
            // Keep libcurl from inheriting ambient system/environment proxy settings
            // unless the user explicitly configured one for Lightpanda.
            try libcurl.curl_easy_setopt(easy, .proxy, DISABLED_PROXY.ptr);
        }
        try libcurl.curl_easy_setopt(easy, .no_proxy, LOOPBACK_NO_PROXY.ptr);

        // tls
        if (ca_blob_) |ca_blob| {
            try libcurl.curl_easy_setopt(easy, .ca_info_blob, ca_blob);
            if (http_proxy != null) {
                try libcurl.curl_easy_setopt(easy, .proxy_ca_info_blob, ca_blob);
            }
        } else {
            assert(config.tlsVerifyHost() == false, "Http.init tls_verify_host", .{});

            try libcurl.curl_easy_setopt(easy, .ssl_verify_host, false);
            try libcurl.curl_easy_setopt(easy, .ssl_verify_peer, false);

            if (http_proxy != null) {
                try libcurl.curl_easy_setopt(easy, .proxy_ssl_verify_host, false);
                try libcurl.curl_easy_setopt(easy, .proxy_ssl_verify_peer, false);
            }
        }

        // compression, don't remove this. CloudFront will send gzip content
        // even if we don't support it, and then it won't be decompressed.
        // empty string means: use whatever's available
        try libcurl.curl_easy_setopt(easy, .accept_encoding, "");

        // debug
        if (comptime ENABLE_DEBUG) {
            try libcurl.curl_easy_setopt(easy, .verbose, true);

            // Sometimes the default debug output hides some useful data. You can
            // uncomment the following line (BUT KEEP THE LIVE ABOVE AS-IS), to
            // get more control over the data (specifically, the `CURLINFO_TEXT`
            // can include useful data).

            // try libcurl.curl_easy_setopt(easy, .debug_function, debugCallback);
        }

        return .{
            .easy = easy,
        };
    }

    pub fn deinit(self: *const Connection) void {
        libcurl.curl_easy_cleanup(self.easy);
    }

    pub fn setURL(self: *const Connection, url: [:0]const u8) !void {
        try libcurl.curl_easy_setopt(self.easy, .url, url.ptr);
    }

    // a libcurl request has 2 methods. The first is the method that
    // controls how libcurl behaves. This specifically influences how redirects
    // are handled. For example, if you do a POST and get a 301, libcurl will
    // change that to a GET. But if you do a POST and get a 308, libcurl will
    // keep the POST (and re-send the body).
    // The second method is the actual string that's included in the request
    // headers.
    // These two methods can be different - you can tell curl to behave as though
    // you made a GET, but include "POST" in the request header.
    //
    // Here, we're only concerned about the 2nd method. If we want, we'll set
    // the first one based on whether or not we have a body.
    //
    // It's important that, for each use of this connection, we set the 2nd
    // method. Else, if we make a HEAD request and re-use the connection, but
    // DON'T reset this, it'll keep making HEAD requests.
    // (I don't know if it's as important to reset the 1st method, or if libcurl
    // can infer that based on the presence of the body, but we also reset it
    // to be safe);
    pub fn setMethod(self: *const Connection, method: Method) !void {
        const easy = self.easy;
        const m: [:0]const u8 = switch (method) {
            .GET => "GET",
            .POST => "POST",
            .PUT => "PUT",
            .DELETE => "DELETE",
            .HEAD => "HEAD",
            .OPTIONS => "OPTIONS",
            .PATCH => "PATCH",
            .PROPFIND => "PROPFIND",
        };
        try libcurl.curl_easy_setopt(easy, .custom_request, m.ptr);
    }

    pub fn setBody(self: *const Connection, body: []const u8) !void {
        const easy = self.easy;
        try libcurl.curl_easy_setopt(easy, .post, true);
        try libcurl.curl_easy_setopt(easy, .post_field_size, body.len);
        try libcurl.curl_easy_setopt(easy, .copy_post_fields, body.ptr);
    }

    pub fn setGetMode(self: *const Connection) !void {
        try libcurl.curl_easy_setopt(self.easy, .http_get, true);
    }

    pub fn setHeaders(self: *const Connection, headers: *Headers) !void {
        try libcurl.curl_easy_setopt(self.easy, .http_header, headers.headers);
    }

    pub fn setCookies(self: *const Connection, cookies: [*c]const u8) !void {
        try libcurl.curl_easy_setopt(self.easy, .cookie, cookies);
    }

    pub fn setPrivate(self: *const Connection, ptr: *anyopaque) !void {
        try libcurl.curl_easy_setopt(self.easy, .private, ptr);
    }

    pub fn setProxyCredentials(self: *const Connection, creds: [:0]const u8) !void {
        try libcurl.curl_easy_setopt(self.easy, .proxy_user_pwd, creds.ptr);
    }

    pub fn setCallbacks(
        self: *const Connection,
        comptime header_cb: libcurl.CurlHeaderFunction,
        comptime data_cb: libcurl.CurlWriteFunction,
    ) !void {
        try libcurl.curl_easy_setopt(self.easy, .header_data, self.easy);
        try libcurl.curl_easy_setopt(self.easy, .header_function, header_cb);
        try libcurl.curl_easy_setopt(self.easy, .write_data, self.easy);
        try libcurl.curl_easy_setopt(self.easy, .write_function, data_cb);
    }

    pub fn setProxy(self: *const Connection, proxy: ?[*:0]const u8) !void {
        try libcurl.curl_easy_setopt(self.easy, .proxy, proxy);
    }

    pub fn setTlsVerify(self: *const Connection, verify: bool, use_proxy: bool) !void {
        try libcurl.curl_easy_setopt(self.easy, .ssl_verify_host, verify);
        try libcurl.curl_easy_setopt(self.easy, .ssl_verify_peer, verify);
        if (use_proxy) {
            try libcurl.curl_easy_setopt(self.easy, .proxy_ssl_verify_host, verify);
            try libcurl.curl_easy_setopt(self.easy, .proxy_ssl_verify_peer, verify);
        }
    }

    pub fn getEffectiveUrl(self: *const Connection) ![*c]const u8 {
        var url: [*c]u8 = undefined;
        try libcurl.curl_easy_getinfo(self.easy, .effective_url, &url);
        return url;
    }

    pub fn getResponseCode(self: *const Connection) !u16 {
        var status: c_long = undefined;
        try libcurl.curl_easy_getinfo(self.easy, .response_code, &status);
        if (status < 0 or status > std.math.maxInt(u16)) {
            return 0;
        }
        return @intCast(status);
    }

    pub fn getRedirectCount(self: *const Connection) !u32 {
        var count: c_long = undefined;
        try libcurl.curl_easy_getinfo(self.easy, .redirect_count, &count);
        return @intCast(count);
    }

    pub fn getResponseHeader(self: *const Connection, name: [:0]const u8, index: usize) ?HeaderValue {
        var hdr: ?*libcurl.CurlHeader = null;
        libcurl.curl_easy_header(self.easy, name, index, .header, -1, &hdr) catch |err| {
            // ErrorHeader includes OutOfMemory — rare but real errors from curl internals.
            // Logged and returned as null since callers don't expect errors.
            log.err(.http, "get response header", .{
                .name = name,
                .err = err,
            });
            return null;
        };
        const h = hdr orelse return null;
        return .{
            .amount = h.amount,
            .value = std.mem.span(h.value),
        };
    }

    pub fn getPrivate(self: *const Connection) !*anyopaque {
        var private: *anyopaque = undefined;
        try libcurl.curl_easy_getinfo(self.easy, .private, &private);
        return private;
    }

    // These are headers that may not be send to the users for inteception.
    pub fn secretHeaders(_: *const Connection, headers: *Headers, http_headers: *const Config.HttpHeaders) !void {
        if (http_headers.proxy_bearer_header) |hdr| {
            try headers.add(hdr);
        }
    }

    pub fn request(self: *const Connection, http_headers: *const Config.HttpHeaders) !u16 {
        var header_list = try Headers.init(http_headers.user_agent_header);
        defer header_list.deinit();
        try self.secretHeaders(&header_list, http_headers);
        try self.setHeaders(&header_list);

        // Add cookies.
        if (header_list.cookies) |cookies| {
            try self.setCookies(cookies);
        }

        try libcurl.curl_easy_perform(self.easy);
        return self.getResponseCode();
    }
};

pub const Handles = struct {
    connections: []Connection,
    dirty: HandleList,
    in_use: HandleList,
    available: HandleList,
    multi: *libcurl.CurlM,
    performing: bool = false,

    pub const HandleList = std.DoublyLinkedList;

    pub fn init(
        allocator: Allocator,
        ca_blob: ?libcurl.CurlBlob,
        config: *const Config,
    ) !Handles {
        const count: usize = config.httpMaxConcurrent();
        if (count == 0) return error.InvalidMaxConcurrent;

        const multi = libcurl.curl_multi_init() orelse return error.FailedToInitializeMulti;
        errdefer libcurl.curl_multi_cleanup(multi) catch {};

        try libcurl.curl_multi_setopt(multi, .max_host_connections, config.httpMaxHostOpen());

        const connections = try allocator.alloc(Connection, count);
        errdefer allocator.free(connections);

        var available: HandleList = .{};
        for (0..count) |i| {
            connections[i] = try Connection.init(ca_blob, config);
            available.append(&connections[i].node);
        }

        return .{
            .dirty = .{},
            .in_use = .{},
            .connections = connections,
            .available = available,
            .multi = multi,
        };
    }

    pub fn deinit(self: *Handles, allocator: Allocator) void {
        for (self.connections) |*conn| {
            conn.deinit();
        }
        allocator.free(self.connections);
        libcurl.curl_multi_cleanup(self.multi) catch {};
    }

    pub fn hasAvailable(self: *const Handles) bool {
        return self.available.first != null;
    }

    pub fn get(self: *Handles) ?*Connection {
        if (self.available.popFirst()) |node| {
            self.in_use.append(node);
            return @as(*Connection, @fieldParentPtr("node", node));
        }
        return null;
    }

    pub fn add(self: *Handles, conn: *const Connection) !void {
        try libcurl.curl_multi_add_handle(self.multi, conn.easy);
    }

    pub fn remove(self: *Handles, conn: *Connection) void {
        if (libcurl.curl_multi_remove_handle(self.multi, conn.easy)) {
            self.isAvailable(conn);
        } else |err| {
            // can happen if we're in a perform() call, so we'll queue this
            // for cleanup later.
            const node = &conn.node;
            self.in_use.remove(node);
            self.dirty.append(node);
            log.warn(.http, "multi remove handle", .{ .err = err });
        }
    }

    pub fn isAvailable(self: *Handles, conn: *Connection) void {
        const node = &conn.node;
        self.in_use.remove(node);
        self.available.append(node);
    }

    pub fn perform(self: *Handles) !c_int {
        self.performing = true;
        defer self.performing = false;

        const multi = self.multi;
        var running: c_int = undefined;
        try libcurl.curl_multi_perform(self.multi, &running);

        {
            const list = &self.dirty;
            while (list.first) |node| {
                list.remove(node);
                const conn: *Connection = @fieldParentPtr("node", node);
                if (libcurl.curl_multi_remove_handle(multi, conn.easy)) {
                    self.available.append(node);
                } else |err| {
                    log.fatal(.http, "multi remove handle", .{ .err = err, .src = "perform" });
                    @panic("multi_remove_handle");
                }
            }
        }

        return running;
    }

    pub fn poll(self: *Handles, extra_fds: []libcurl.CurlWaitFd, timeout_ms: c_int) !void {
        if (timeout_ms <= 0) {
            return;
        }
        try libcurl.curl_multi_poll(self.multi, extra_fds, timeout_ms, null);
    }

    pub const MultiMessage = struct {
        conn: Connection,
        err: ?Error,
    };

    pub fn readMessage(self: *Handles) ?MultiMessage {
        var messages_count: c_int = 0;
        const msg = libcurl.curl_multi_info_read(self.multi, &messages_count) orelse return null;
        return switch (msg.data) {
            .done => |err| .{
                .conn = .{ .easy = msg.easy_handle },
                .err = err,
            },
            else => unreachable,
        };
    }
};

// TODO: on BSD / Linux, we could just read the PEM file directly.
// This whole rescan + decode is really just needed for MacOS. On Linux
// bundle.rescan does find the .pem file(s) which could be in a few different
// places, so it's still useful, just not efficient.
pub fn loadCerts(allocator: Allocator) !libcurl.CurlBlob {
    var bundle: std.crypto.Certificate.Bundle = .{};
    try bundle.rescan(allocator);
    defer bundle.deinit(allocator);

    const bytes = bundle.bytes.items;
    if (bytes.len == 0) {
        log.warn(.app, "No system certificates", .{});
        return .{
            .len = 0,
            .flags = 0,
            .data = bytes.ptr,
        };
    }

    const encoder = std.base64.standard.Encoder;
    const encoded_len = encoder.calcSize(bytes.len);

    const pem_header = "-----BEGIN CERTIFICATE-----\n";
    const pem_footer = "\n-----END CERTIFICATE-----\n";

    // Base64 encoded is always 4/3 of the binary size, so worst-case about 33% larger.
    // Use checked arithmetic to avoid overflow and satisfy static analysis.
    const total_size = std.math.add(usize, pem_header.len + pem_footer.len, encoded_len) catch {
        return error.OutOfMemory;
    };

    var pem = try allocator.alloc(u8, total_size);
    errdefer allocator.free(pem);

    @memcpy(pem[0..pem_header.len], pem_header);
    _ = encoder.encode(pem[pem_header.len .. pem_header.len + encoded_len], bytes);
    @memcpy(pem[pem_header.len + encoded_len ..], pem_footer);

    return .{
        .data = @ptrCast(pem.ptr),
        .len = pem.len,
        .flags = libcurl.CURL_BLOB_COPY,
    };
}

pub const Multi = struct {
    arena: ArenaAllocator,
    handles: Handles,
    ca_blob: ?libcurl.CurlBlob,

    pub fn init(allocator: Allocator, config: *const Config) !Multi {
        const ca_blob = if (config.tls_verify_host == false) null else try loadCerts(allocator);
        errdefer if (ca_blob) |ca| allocator.free(ca.data[0..ca.len]);

        var arena = ArenaAllocator.init(allocator);
        errdefer arena.deinit();

        const handles = try Handles.init(arena.allocator(), ca_blob, config);
        errdefer handles.deinit(arena.allocator());

        return .{
            .arena = arena,
            .handles = handles,
            .ca_blob = ca_blob,
        };
    }

    pub fn deinit(self: *Multi) void {
        const allocator = self.arena.child_allocator;
        self.handles.deinit(self.arena.allocator());
        self.arena.deinit();
        if (self.ca_blob) |ca| {
            allocator.free(ca.data[0..ca.len]);
        }
    }

    pub fn request(self: *Multi, comptime ResponseType: type, args: RequestArgs(ResponseType)) !Transfer(ResponseType) {
        const conn = self.handles.get() orelse return error.NoConnectionAvailable;
        errdefer self.handles.isAvailable(conn);

        const ca_blob = self.ca_blob;
        const config = args.config;
        const alloc = self.arena.allocator();

        // reset our connection in case this was previously used with different options
        try conn.setCallbacks(curlHeaderCallback, curlDataCallback(ResponseType));
        try conn.setURL(args.url);
        try conn.setMethod(args.method);

        if (ca_blob) |ca| {
            // setTlsVerify handles the proxy options only when a proxy is configured.
            const use_proxy = config.httpProxy() != null;
            try conn.setTlsVerify(config.tlsVerifyHost(), use_proxy);
            try conn.setPrivate(null);
            _ = ca; // silence unused in some build modes
        } else {
            try conn.setPrivate(null);
        }

        if (args.proxy) |proxy| {
            try conn.setProxy(proxy);
        }

        if (args.proxy_credentials) |creds| {
            try conn.setProxyCredentials(creds);
        }

        switch (args.body) {
            .none => try conn.setGetMode(),
            .some => |body| try conn.setBody(body),
        }

        var header_list = try Headers.init(args.http_headers.user_agent_header);
        errdefer header_list.deinit();
        if (args.headers) |headers| {
            var it = headers.iterator();
            while (it.next()) |header| {
                var line = try std.fmt.allocPrintZ(alloc, "{s}: {s}", .{ header.name, header.value });
                try header_list.add(line.ptr);
            }
        }

        try conn.secretHeaders(&header_list, args.http_headers);
        try conn.setHeaders(&header_list);

        if (args.cookies) |cookies| {
            // libcurl doesn't have an API that accepts a list of cookies, just a
            // string. So we have to form that string here.
            var writer = try std.Io.Writer.Allocating.initCapacity(alloc, cookies.len);
            try writer.writer.writeAll(cookies);
            const cookie_str = try writer.toOwnedSliceSentinel(0);
            header_list.cookies = cookie_str.ptr;
            try conn.setCookies(cookie_str.ptr);
        }

        var transfer = try Transfer(ResponseType).init(alloc, conn, args.state, args.response, header_list);
        errdefer transfer.deinit();
        try conn.setPrivate(&transfer);
        try self.handles.add(conn);
        return transfer;
    }
};

pub const RequestBody = union(enum) {
    none,
    some: []const u8,
};

pub fn RequestArgs(comptime ResponseType: type) type {
    return struct {
        config: *const Config,
        state: *anyopaque,
        response: *ResponseType,
        url: [:0]const u8,
        method: Method = .GET,
        body: RequestBody = .none,
        headers: ?*Headers = null,
        cookies: ?[]const u8 = null,
        http_headers: *const Config.HttpHeaders,
        proxy: ?[*:0]const u8 = null,
        proxy_credentials: ?[:0]const u8 = null,
    };
}

pub fn Transfer(comptime ResponseType: type) type {
    return struct {
        const Self = @This();
        conn: *Connection,
        state: *anyopaque,
        response: *ResponseType,
        response_head: ResponseHead = .{
            .status = 0,
            .url = null,
            .redirect_count = 0,
        },
        headers: Headers,
        allocator: Allocator,
        promise: ?std.Thread.ResetEvent = null,
        done: bool = false,
        err: ?Error = null,
        content_type_buf: [ResponseHead.MAX_CONTENT_TYPE_LEN]u8 = undefined,

        pub fn init(allocator: Allocator, conn: *Connection, state: *anyopaque, response: *ResponseType, headers: Headers) !Self {
            return .{
                .conn = conn,
                .state = state,
                .response = response,
                .headers = headers,
                .allocator = allocator,
                .response_head = .{
                    .status = 0,
                    .url = null,
                    .redirect_count = 0,
                },
            };
        }

        pub fn deinit(self: *Self) void {
            self.headers.deinit();
            if (self.promise) |*p| {
                p.deinit();
            }
        }

        pub fn finish(self: *Self) void {
            self.done = true;
            if (self.promise) |*p| {
                p.set();
            }
        }

        pub fn setPromise(self: *Self) !void {
            if (self.promise != null) return;
            self.promise = std.Thread.ResetEvent{};
        }

        pub fn wait(self: *Self) void {
            if (self.promise) |*p| {
                p.wait();
            }
        }

        pub fn responseHeaderIterator(self: *Self) HeaderIterator {
            if (self.response_head._injected_headers.len > 0) {
                return .{ .list = .{ .list = self.response_head._injected_headers } };
            }
            return .{ .curl = .{ .conn = self.conn } };
        }

        pub fn contentType(self: *Self) ?[]u8 {
            return self.response_head.contentType();
        }

        pub fn head(self: *Self) *ResponseHead {
            return &self.response_head;
        }

        pub fn getResponseCode(self: *Self) !u16 {
            return self.conn.getResponseCode();
        }

        pub fn hasChallenge(self: *Self) !bool {
            const status = self.response_head.status;
            if (status != 401 and status != 407) {
                return false;
            }
            const header_name: [:0]const u8 = if (status == 401) "WWW-Authenticate" else "Proxy-Authenticate";
            return self.conn.getResponseHeader(header_name, 0) != null;
        }

        pub fn challenges(self: *Self, allocator: Allocator) !std.ArrayList(AuthChallenge) {
            const status = self.response_head.status;
            if (status != 401 and status != 407) {
                return .{};
            }
            const header_name: [:0]const u8 = if (status == 401) "WWW-Authenticate" else "Proxy-Authenticate";
            var idx: usize = 0;
            var challenge_list: std.ArrayList(AuthChallenge) = .{};
            errdefer challenge_list.deinit(allocator);
            while (self.conn.getResponseHeader(header_name, idx)) |hdr| : (idx += 1) {
                const line = try std.fmt.allocPrint(allocator, "{s}: {s}", .{ header_name, hdr.value });
                defer allocator.free(line);
                const challenge = AuthChallenge.parse(status, line) catch |err| {
                    log.warn(.page, "auth challenge parse failed", .{ .err = err, .line = line });
                    continue;
                };
                try challenge_list.append(allocator, challenge);
            }
            return challenge_list;
        }

        pub fn fulfill(self: *Self, options: struct {
            status: u16,
            body: []const u8,
            headers: []const Header = &.{},
            content_type: ?[]const u8 = null,
        }) !void {
            // remove body and header callbacks so that curl doesn't write anymore
            try libcurl.curl_easy_setopt(self.conn.easy, .write_function, null);
            try libcurl.curl_easy_setopt(self.conn.easy, .header_function, null);
            self.response_head.status = options.status;
            self.response_head._injected_headers = options.headers;
            if (options.content_type) |ct| {
                const len = @min(ct.len, ResponseHead.MAX_CONTENT_TYPE_LEN);
                @memcpy(self.response_head._content_type[0..len], ct[0..len]);
                self.response_head._content_type_len = len;
            }
            try self.response.receive(self.state, options.body);
        }
    };
}

fn curlHeaderCallback(
    buf: [*]u8,
    size: usize,
    nitems: usize,
    user_data: ?*anyopaque,
) callconv(.c) usize {
    const byte_count = size * nitems;
    const transfer: *Transfer(anyopaque) = @ptrCast(@alignCast(user_data orelse return 0));
    var response_head = &transfer.response_head;

    // response_status
    if (response_head.status == 0) {
        const line = buf[0..byte_count];
        const first = std.mem.indexOfScalar(u8, line, ' ') orelse return 0;
        const second = std.mem.indexOfScalarPos(u8, line, first + 1, ' ') orelse return 0;
        response_head.status = std.fmt.parseInt(u16, line[first + 1 .. second], 10) catch return 0;
        return byte_count;
    }

    const ct = if (response_head._content_type_len == 0) blk: {
        // content-type
        const line = buf[0..byte_count];
        if (std.ascii.startsWithIgnoreCase(line, "content-type:")) {
            const end = std.mem.indexOfScalar(u8, line, ';') orelse byte_count;
            const content_type = std.mem.trim(u8, line[13..end], " \t\r\n");
            if (content_type.len > 0 and content_type.len <= ResponseHead.MAX_CONTENT_TYPE_LEN) {
                break :blk content_type;
            }
        }
        break :blk null;
    } else null;

    // If we're intercepting authentication (401 or 407) don't write the body.
    // We have to wait for the client code to see the status and authorize the challenge first.
    if (response_head.status == 401 or response_head.status == 407) {
        return byte_count;
    }

    const response = transfer.response;
    response.receiveHeader(transfer.state, .{ .status = response_head.status, .content_type = ct }) catch return 0;

    if (ct) |content_type| {
        const len = content_type.len;
        @memcpy(response_head._content_type[0..len], content_type);
        response_head._content_type_len = len;
    }

    return byte_count;
}

fn curlDataCallback(comptime ResponseType: type) libcurl.CurlWriteFunction {
    return struct {
        fn callback(
            buf: [*]u8,
            size: usize,
            nitems: usize,
            user_data: ?*anyopaque,
        ) callconv(.c) usize {
            const transfer: *Transfer(ResponseType) = @ptrCast(@alignCast(user_data orelse return 0));
            const byte_count = size * nitems;
            const response = transfer.response;
            response.receive(transfer.state, buf[0..byte_count]) catch return 0;
            return byte_count;
        }
    }.callback;
}

pub fn websocketHeader(buf: []u8, comptime message_type: enum { text, binary, pong }, len: usize) []const u8 {
    buf[0] = switch (message_type) {
        .text => 129,
        .binary => 130,
        .pong => 138,
    };

    if (len <= 125) {
        buf[1] = @intCast(len);
        return buf[0..2];
    }

    if (len <= std.math.maxInt(u16)) {
        buf[1] = 126;
        const len_16 = @as(u16, @intCast(len));
        buf[2] = @intCast(len_16 >> 8);
        buf[3] = @intCast(len_16);
        return buf[0..4];
    }

    buf[1] = 127;
    const len_64 = @as(u64, @intCast(len));
    buf[2] = @intCast(len_64 >> 56);
    buf[3] = @intCast(len_64 >> 48);
    buf[4] = @intCast(len_64 >> 40);
    buf[5] = @intCast(len_64 >> 32);
    buf[6] = @intCast(len_64 >> 24);
    buf[7] = @intCast(len_64 >> 16);
    buf[8] = @intCast(len_64 >> 8);
    buf[9] = @intCast(len_64);
    return buf[0..10];
}

pub fn fillWebsocketHeader(buf: std.ArrayList(u8)) []const u8 {
    // There should be 10 bytes free in front of our payload. We might need
    // less depending on the payload size.
    const len = buf.items.len - 10;
    const slice = buf.items;
    if (len <= 125) {
        slice[8] = 129;
        slice[9] = @intCast(len);
        return slice[8..];
    }

    if (len <= std.math.maxInt(u16)) {
        slice[6] = 129;
        slice[7] = 126;
        const len_16 = @as(u16, @intCast(len));
        slice[8] = @intCast(len_16 >> 8);
        slice[9] = @intCast(len_16);
        return slice[6..];
    }

    slice[0] = 129;
    slice[1] = 127;
    const len_64 = @as(u64, @intCast(len));
    slice[2] = @intCast(len_64 >> 56);
    slice[3] = @intCast(len_64 >> 48);
    slice[4] = @intCast(len_64 >> 40);
    slice[5] = @intCast(len_64 >> 32);
    slice[6] = @intCast(len_64 >> 24);
    slice[7] = @intCast(len_64 >> 16);
    slice[8] = @intCast(len_64 >> 8);
    slice[9] = @intCast(len_64);
    return slice[0..];
}

// Shared between our websocket client and our websocket server
fn mask(mask_: []const u8, data: []u8) void {
    const mask_4 = std.mem.bytesAsValue(u32, mask_[0..4]).*;
    var n = data.len / 4;
    var i: usize = 0;
    while (n > 0) : ({
        n -= 1;
        i += 4;
    }) {
        const value = std.mem.bytesAsValue(u32, data[i .. i + 4]);
        value.* ^= mask_4;
    }

    const shift: u3 = @intCast((data.len & 3) * 8);
    const rem = mask_4 << shift | mask_4 >> (32 - shift);
    n = data.len & 3;
    while (n > 0) : ({
        n -= 1;
        i += 1;
    }) {
        data[i] ^= @intCast(rem >> ((n - 1) * 8));
    }
}

pub fn websocketHandshake(allocator: Allocator, request: []u8, config: *const Config) !WsConnection {
    // must be at least large enough for a valid request-line + \r\n\r\n
    if (request.len < 16) {
        return error.InvalidRequest;
    }

    // path can be empty, but it must exists
    const path_start = std.mem.indexOfScalar(u8, request, ' ') orelse return error.InvalidRequest;
    const path_end = std.mem.indexOfScalarPos(u8, request, path_start + 1, ' ') orelse return error.InvalidRequest;
    if (path_end == path_start + 1) {
        return error.InvalidRequest;
    }

    const path = request[path_start + 1 .. path_end];

    const socket = blk: {
        // /json/version
        if (std.mem.eql(u8, path, "/json/version")) {
            break :blk try websocketHandshakeForJsonVersion(request, config);
        }

        // /devtools/browser/blah
        const browser_prefix = "/devtools/browser/";
        if (path.len > browser_prefix.len and std.mem.eql(u8, path[0..browser_prefix.len], browser_prefix)) {
            if (std.mem.indexOfScalarPos(u8, path, browser_prefix.len, '/')) |_| {
                return error.InvalidRequest;
            }
            break :blk try websocketHandshakeForBrowser(request, config);
        }

        // /devtools/page/blah
        const page_prefix = "/devtools/page/";
        if (path.len > page_prefix.len and std.mem.eql(u8, path[0..page_prefix.len], page_prefix)) {
            if (std.mem.indexOfScalarPos(u8, path, page_prefix.len, '/')) |_| {
                return error.InvalidRequest;
            }
            break :blk try websocketHandshakeForPage(request, config);
        }

        return error.NotFound;
    };

    return WsConnection.init(socket, allocator, config.json_version_response, config.cdp_timeout);
}

fn websocketHandshakeForJsonVersion(request: []u8, config: *const Config) !posix.socket_t {
    if (request.len < 16) {
        return error.InvalidRequest;
    }

    var path_end = std.mem.indexOfScalar(u8, request, ' ') orelse return error.InvalidRequest;
    if (path_end < 3) {
        return error.InvalidRequest;
    }

    const path = request[4..path_end];
    if (!std.mem.eql(u8, path, "/json/version")) {
        return error.InvalidRequest;
    }

    path_end = std.mem.indexOfScalarPos(u8, request, path_end + 1, ' ') orelse return error.InvalidRequest;
    if (path_end < 6) {
        return error.InvalidRequest;
    }

    const protocol = request[path_end + 1 .. path_end + 9];
    if (!std.ascii.eqlIgnoreCase(protocol, "HTTP/1.1")) {
        return error.InvalidProtocol;
    }

    const socket = config.websocket_socket orelse return error.InvalidRequest;
    return socket;
}

fn websocketHandshakeForBrowser(request: []u8, config: *const Config) !posix.socket_t {
    if (request.len < 16) {
        return error.InvalidRequest;
    }

    var path_end = std.mem.indexOfScalar(u8, request, ' ') orelse return error.InvalidRequest;
    if (path_end < 3) {
        return error.InvalidRequest;
    }

    const path = request[4..path_end];
    const browser_prefix = "/devtools/browser/";
    if (path.len <= browser_prefix.len or !std.mem.eql(u8, path[0..browser_prefix.len], browser_prefix)) {
        return error.InvalidRequest;
    }

    if (std.mem.indexOfScalarPos(u8, path, browser_prefix.len, '/')) |_| {
        return error.InvalidRequest;
    }

    path_end = std.mem.indexOfScalarPos(u8, request, path_end + 1, ' ') orelse return error.InvalidRequest;
    if (path_end < 6) {
        return error.InvalidRequest;
    }

    const protocol = request[path_end + 1 .. path_end + 9];
    if (!std.ascii.eqlIgnoreCase(protocol, "HTTP/1.1")) {
        return error.InvalidProtocol;
    }

    const socket = config.websocket_socket orelse return error.InvalidRequest;
    return socket;
}

fn websocketHandshakeForPage(request: []u8, config: *const Config) !posix.socket_t {
    if (request.len < 16) {
        return error.InvalidRequest;
    }

    var path_end = std.mem.indexOfScalar(u8, request, ' ') orelse return error.InvalidRequest;
    if (path_end < 3) {
        return error.InvalidRequest;
    }

    const path = request[4..path_end];
    const page_prefix = "/devtools/page/";
    if (path.len <= page_prefix.len or !std.mem.eql(u8, path[0..page_prefix.len], page_prefix)) {
        return error.InvalidRequest;
    }

    if (std.mem.indexOfScalarPos(u8, path, page_prefix.len, '/')) |_| {
        return error.InvalidRequest;
    }

    path_end = std.mem.indexOfScalarPos(u8, request, path_end + 1, ' ') orelse return error.InvalidRequest;
    if (path_end < 6) {
        return error.InvalidRequest;
    }

    const protocol = request[path_end + 1 .. path_end + 9];
    if (!std.ascii.eqlIgnoreCase(protocol, "HTTP/1.1")) {
        return error.InvalidProtocol;
    }

    const socket = config.websocket_socket orelse return error.InvalidRequest;
    return socket;
}

pub fn websocketAcceptKey(allocator: Allocator, key: []const u8) ![]u8 {
    var sha1 = std.crypto.hash.Sha1.init(.{});
    sha1.update(key);
    sha1.update("258EAFA5-E914-47DA-95CA-C5AB0DC85B11");
    var digest: [20]u8 = undefined;
    sha1.final(&digest);

    const encoder = std.base64.standard.Encoder;
    const encoded_len = encoder.calcSize(digest.len);
    var encoded = try allocator.alloc(u8, encoded_len);
    _ = encoder.encode(encoded, &digest);
    return encoded;
}

pub const Client = struct {
    arena: ArenaAllocator,
    conn: Connection,
    reader: Reader(false),

    pub fn init(allocator: Allocator, address: std.net.Address) !Client {
        var arena = ArenaAllocator.init(allocator);
        errdefer arena.deinit();

        const sock = try posix.socket(address.any.family, posix.SOCK.STREAM, posix.IPPROTO.TCP);
        errdefer posix.close(sock);

        try posix.connect(sock, &address.any, address.getOsSockLen());

        return .{
            .arena = arena,
            .conn = .{ .socket = sock },
            .reader = try Reader(false).init(arena.allocator()),
        };
    }

    pub fn deinit(self: *Client) void {
        posix.close(self.conn.socket);
        self.reader.deinit();
        self.arena.deinit();
    }

    pub fn send(self: *Client, data: []const u8) !void {
        // client -> server messages need to be masked
        var header_buf: [14]u8 = undefined;
        const header = websocketHeader(&header_buf, .text, data.len);

        const allocator = self.arena.allocator();
        const framed = try allocator.alloc(u8, header.len + 4 + data.len);
        @memcpy(framed[0..header.len], header);

        // add the mask bit
        framed[1] = framed[1] | 128;

        const mask_start = header.len;
        const mask_ = framed[mask_start .. mask_start + 4];
        mask_.* = .{ 1, 2, 200, 240 };

        const payload = framed[mask_start + 4 ..];
        @memcpy(payload, data);
        mask(mask_, payload);

        try self.conn.send(framed);
        _ = self.arena.reset(.retain_capacity);
    }

    pub fn receive(self: *Client) !?Message {
        var reader = &self.reader;

        while (reader.next()) |message| {
            return message;
        }

        const n = try self.conn.read();
        reader.len += n;

        return try reader.next();
    }

    pub const Message = Reader(false).Message;
};

pub fn websocketConnect(allocator: Allocator, address: std.net.Address, endpoint: []const u8) !Client {
    var c = try Client.init(allocator, address);
    errdefer c.deinit();

    const rand = std.crypto.random;
    var nonce: [16]u8 = undefined;
    rand.bytes(&nonce);

    const encoder = std.base64.standard.Encoder;
    const expected_response = try allocator.alloc(u8, encoder.calcSize(20));
    defer allocator.free(expected_response);
    const key = try allocator.alloc(u8, encoder.calcSize(16));
    defer allocator.free(key);
    _ = encoder.encode(key, &nonce);

    {
        var sha1 = std.crypto.hash.Sha1.init(.{});
        sha1.update(key);
        sha1.update("258EAFA5-E914-47DA-95CA-C5AB0DC85B11");
        var digest: [20]u8 = undefined;
        sha1.final(&digest);
        _ = encoder.encode(expected_response, &digest);
    }

    var buffer = std.ArrayList(u8).empty;
    defer buffer.deinit(allocator);
    try buffer.appendSlice(allocator, "GET ");
    try buffer.appendSlice(allocator, endpoint);
    try buffer.appendSlice(allocator, " HTTP/1.1\r\n");
    try buffer.appendSlice(allocator, "Host: localhost\r\n");
    try buffer.appendSlice(allocator, "Upgrade: websocket\r\n");
    try buffer.appendSlice(allocator, "Connection: Upgrade\r\n");
    try buffer.appendSlice(allocator, "Sec-Websocket-Version: 13\r\n");
    try buffer.appendSlice(allocator, "Sec-Websocket-Key: ");
    try buffer.appendSlice(allocator, key);
    try buffer.appendSlice(allocator, "\r\n\r\n");

    const request = buffer.items;
    try c.conn.send(request);

    var response_header: [512]u8 = undefined;
    const n = try c.conn.read(response_header[0..]);
    if (n < 20) {
        return error.InvalidResponse;
    }
    const response = response_header[0..n];
    if (std.mem.eql(u8, response[0..13], "HTTP/1.1 101 ") == false) {
        return error.InvalidResponse;
    }

    const accept_key_index = std.mem.indexOf(u8, response, "Sec-Websocket-Accept: ") orelse return error.InvalidResponse;
    const end = std.mem.indexOfScalarPos(u8, response, accept_key_index, '\r') orelse return error.InvalidResponse;
    const accept_key = std.mem.trim(u8, response[accept_key_index + 22 .. end], " ");
    if (std.mem.eql(u8, accept_key, expected_response) == false) {
        return error.InvalidResponse;
    }

    return c;
}

pub const Reader = struct {
    const MessageType = enum {
        text,
        binary,
        close,
        ping,
        pong,
    };

    pub const Message = struct {
        data: []const u8,
        type: MessageType,
        cleanup_fragment: bool,
    };

    pub fn Reader(comptime EXPECT_MASK: bool) type {
        return struct {
            const Self = @This();
            buf: []u8,
            len: usize = 0,
            pos: usize = 0,
            allocator: Allocator,
            fragments: ?Fragments = null,

            const Fragments = struct {
                message: std.ArrayList(u8),
                type: MessageType,
            };

            pub fn init(allocator: Allocator) !Self {
                const buf = try allocator.alloc(u8, 4096);
                return .{
                    .buf = buf,
                    .allocator = allocator,
                };
            }

            fn growBuffer(allocator: Allocator, old: []u8, new_len: usize) ![]u8 {
                var new = try allocator.alloc(u8, new_len);
                errdefer allocator.free(new);
                @memcpy(new[0..old.len], old);
                allocator.free(old);
                return new;
            }

            pub fn deinit(self: *Self) void {
                self.cleanup();
                self.allocator.free(self.buf);
            }

            pub fn cleanup(self: *Self) void {
                if (self.fragments) |*f| {
                    f.message.deinit(self.allocator);
                    self.fragments = null;
                }
            }

            pub fn readBuf(self: *Self) []u8 {
                // We might have read a partial http or websocket message.
                // Subsequent reads must read from where we left off.
                return self.buf[self.len..];
            }

            pub fn next(self: *Self) !?Message {
                LOOP: while (true) {
                    var buf = self.buf[self.pos..self.len];

                    const length_of_len, const message_len = extractLengths(buf) orelse {
                        // we don't have enough bytes
                        return null;
                    };

                    const byte1 = buf[0];

                    if (byte1 & 112 != 0) {
                        return error.ReservedFlags;
                    }

                    if (comptime EXPECT_MASK) {
                        if (buf[1] & 128 != 128) {
                            // client -> server messages _must_ be masked
                            return error.NotMasked;
                        }
                    } else if (buf[1] & 128 != 0) {
                        // server -> client are never masked
                        return error.Masked;
                    }

                    var is_control = false;
                    var is_continuation = false;
                    var message_type: Message.Type = undefined;
                    switch (byte1 & 15) {
                        0 => is_continuation = true,
                        1 => message_type = .text,
                        2 => message_type = .binary,
                        8 => {
                            is_control = true;
                            message_type = .close;
                        },
                        9 => {
                            is_control = true;
                            message_type = .ping;
                        },
                        10 => {
                            is_control = true;
                            message_type = .pong;
                        },
                        else => return error.InvalidMessageType,
                    }

                    if (is_control) {
                        if (message_len > 125) {
                            return error.ControlTooLarge;
                        }
                    } else if (message_len > Config.CDP_MAX_MESSAGE_SIZE) {
                        return error.TooLarge;
                    } else if (message_len > self.buf.len) {
                        const len = self.buf.len;
                        self.buf = try growBuffer(self.allocator, self.buf, message_len);
                        buf = self.buf[0..len];
                        // we need more data
                        return null;
                    } else if (buf.len < message_len) {
                        // we need more data
                        return null;
                    }

                    // prefix + length_of_len + mask
                    const header_len = 2 + length_of_len + if (comptime EXPECT_MASK) 4 else 0;

                    const payload = buf[header_len..message_len];
                    if (comptime EXPECT_MASK) {
                        mask(buf[header_len - 4 .. header_len], payload);
                    }

                    // whatever happens after this, we know where the next message starts
                    self.pos += message_len;

                    const fin = byte1 & 128 == 128;

                    if (is_continuation) {
                        const fragments = &(self.fragments orelse return error.InvalidContinuation);
                        if (fragments.message.items.len + message_len > Config.CDP_MAX_MESSAGE_SIZE) {
                            return error.TooLarge;
                        }

                        try fragments.message.appendSlice(self.allocator, payload);

                        if (fin == false) {
                            // maybe we have more parts of the message waiting
                            continue :LOOP;
                        }

                        // this continuation is done!
                        return .{
                            .type = fragments.type,
                            .data = fragments.message.items,
                            .cleanup_fragment = true,
                        };
                    }

                    const can_be_fragmented = message_type == .text or message_type == .binary;
                    if (self.fragments != null and can_be_fragmented) {
                        // if this isn't a continuation, then we can't have fragments
                        return error.NestedFragementation;
                    }

                    if (fin == false) {
                        if (can_be_fragmented == false) {
                            return error.InvalidContinuation;
                        }

                        // not continuation, and not fin. It has to be the first message
                        // in a fragmented message.
                        var fragments = Fragments{ .message = .{}, .type = message_type };
                        try fragments.message.appendSlice(self.allocator, payload);
                        self.fragments = fragments;
                        continue :LOOP;
                    }

                    return .{
                        .data = payload,
                        .type = message_type,
                        .cleanup_fragment = false,
                    };
                }
            }

            fn extractLengths(buf: []const u8) ?struct { usize, usize } {
                if (buf.len < 2) {
                    return null;
                }

                const length_of_len: usize = switch (buf[1] & 127) {
                    126 => 2,
                    127 => 8,
                    else => 0,
                };

                if (buf.len < length_of_len + 2) {
                    // we definitely don't have enough buf yet
                    return null;
                }

                const message_len = switch (length_of_len) {
                    2 => @as(u16, @intCast(buf[3])) | @as(u16, @intCast(buf[2])) << 8,
                    8 => @as(u64, @intCast(buf[9])) | @as(u64, @intCast(buf[8])) << 8 | @as(u64, @intCast(buf[7])) << 16 | @as(u64, @intCast(buf[6])) << 24 | @as(u64, @intCast(buf[5])) << 32 | @as(u64, @intCast(buf[4])) << 40 | @as(u64, @intCast(buf[3])) << 48 | @as(u64, @intCast(buf[2])) << 56,
                    else => buf[1] & 127,
                } + length_of_len + 2 + if (comptime EXPECT_MASK) 4 else 0; // +2 for header prefix, +4 for mask;

                return .{ length_of_len, message_len };
            }

            // This is called after we've processed complete websocket messages (this
            // only applies to websocket messages).
            // There are three cases:
            // 1 - We don't have any incomplete data (for a subsequent message) in buf.
            //     This is the easier to handle, we can set pos & len to 0.
            // 2 - We have part of the next message, but we know it'll fit in the
            //     remaining buf. We don't need to do anything
            // 3 - We have part of the next message, but either it won't fight into the
            //     remaining buffer, or we don't know (because we don't have enough
            //     of the header to tell the length). We need to "compact" the buffer
            fn compact(self: *Self) void {
                const pos = self.pos;
                const len = self.len;

                assert(pos <= len, "Client.Reader.compact precondition", .{ .pos = pos, .len = len });

                // how many (if any) partial bytes do we have
                const partial_bytes = len - pos;

                if (partial_bytes == 0) {
                    // We have no partial bytes. Setting these to 0 ensures that we
                    // get the best utilization of our buffer
                    self.pos = 0;
                    self.len = 0;
                    return;
                }

                const partial = self.buf[pos..len];

                // If we have enough bytes of the next message to tell its length
                // we'll be able to figure out whether we need to do anything or not.
                if (extractLengths(partial)) |length_meta| {
                    const next_message_len = length_meta.@"1";
                    // if this isn't true, then we have a full message and it
                    // should have been processed.
                    assert(pos <= len, "Client.Reader.compact postcondition", .{ .next_len = next_message_len, .partial = partial_bytes });

                    const missing_bytes = next_message_len - partial_bytes;

                    const free_space = self.buf.len - len;
                    if (missing_bytes < free_space) {
                        // we have enough space in our buffer, as is,
                        return;
                    }
                }

                // We're here because we either don't have enough bytes of the next
                // message, or we know that it won't fit in our buffer as-is.
                std.mem.copyForwards(u8, self.buf, partial);
                self.pos = 0;
                self.len = partial_bytes;
            }
        };
    }
}

// In-place string lowercase
fn toLower(str: []u8) []u8 {
    for (str, 0..) |ch, i| {
        str[i] = std.ascii.toLower(ch);
    }
    return str;
}

pub const WsConnection = struct {
    // CLOSE, 2 length, code
    const CLOSE_NORMAL = [_]u8{ 136, 2, 3, 232 }; // code: 1000
    const CLOSE_TOO_BIG = [_]u8{ 136, 2, 3, 241 }; // 1009
    const CLOSE_PROTOCOL_ERROR = [_]u8{ 136, 2, 3, 234 }; //code: 1002
    // "private-use" close codes must be from 4000-49999
    const CLOSE_TIMEOUT = [_]u8{ 136, 2, 15, 160 }; // code: 4000

    socket: posix.socket_t,
    socket_flags: usize,
    reader: Reader(true),
    send_arena: ArenaAllocator,
    json_version_response: []const u8,
    timeout_ms: u32,

    pub fn init(socket: posix.socket_t, allocator: Allocator, json_version_response: []const u8, timeout_ms: u32) !WsConnection {
        const socket_flags = if (comptime builtin.os.tag == .windows)
            0
        else
            try posix.fcntl(socket, posix.F.GETFL, 0);
        if (comptime builtin.os.tag != .windows) {
            const nonblocking = @as(u32, @bitCast(posix.O{ .NONBLOCK = true }));
            assert(socket_flags & nonblocking == nonblocking, "WsConnection.init blocking", .{});
        }

        var reader = try Reader(true).init(allocator);
        errdefer reader.deinit();

        return .{
            .socket = socket,
            .socket_flags = socket_flags,
            .reader = reader,
            .send_arena = ArenaAllocator.init(allocator),
            .json_version_response = json_version_response,
            .timeout_ms = timeout_ms,
        };
    }

    pub fn deinit(self: *WsConnection) void {
        self.reader.deinit();
        self.send_arena.deinit();
    }

    pub fn send(self: *WsConnection, data: []const u8) !void {
        var pos: usize = 0;
        var changed_to_blocking: bool = false;
        defer _ = self.send_arena.reset(.{ .retain_with_limit = 1024 * 32 });

        defer if (changed_to_blocking and comptime builtin.os.tag != .windows) {
            // We had to change our socket to blocking me to get our write out
            // We need to change it back to non-blocking.
            _ = posix.fcntl(self.socket, posix.F.SETFL, self.socket_flags) catch |err| {
                log.err(.app, "ws restore nonblocking", .{ .err = err });
            };
        };

        LOOP: while (pos < data.len) {
            const written = posix.send(self.socket, data[pos..], 0) catch |err| switch (err) {
                error.WouldBlock => {
                    if (comptime builtin.os.tag == .windows) {
                        std.Thread.sleep(100 * std.time.ns_per_us);
                        continue :LOOP;
                    }

                    // self.socket is nonblocking, because we don't want to block
                    // reads. But our life is a lot easier if we block writes,
                    // largely, because we don't have to maintain a queue of pending
                    // writes (which would each need their own allocations). So
                    // if we get a WouldBlock error, we'll switch the socket to
                    // blocking and switch it back to non-blocking after the write
                    // is complete. Doesn't seem particularly efficiently, but
                    // this should virtually never happen.
                    assert(changed_to_blocking == false, "WsConnection.double block", .{});
                    changed_to_blocking = true;
                    _ = try posix.fcntl(self.socket, posix.F.SETFL, self.socket_flags & ~@as(u32, @bitCast(posix.O{ .NONBLOCK = true })));
                    continue :LOOP;
                },
                else => return err,
            };

            if (written == 0) {
                return error.Closed;
            }
            pos += written;
        }
    }

    const EMPTY_PONG = [_]u8{ 138, 0 };

    fn sendPong(self: *WsConnection, data: []const u8) !void {
        if (data.len == 0) {
            return self.send(&EMPTY_PONG);
        }
        var header_buf: [10]u8 = undefined;
        const header = websocketHeader(&header_buf, .pong, data.len);

        const allocator = self.send_arena.allocator();
        const framed = try allocator.alloc(u8, header.len + data.len);
        @memcpy(framed[0..header.len], header);
        @memcpy(framed[header.len..], data);
        return self.send(framed);
    }

    // called by CDP
    // Websocket frames have a variable length header. For server-client,
    // it could be anywhere from 2 to 10 bytes. Our IO.Loop doesn't have
    // writev, so we need to get creative. We'll JSON serialize to a
    // buffer, where the first 10 bytes are reserved. We can then backfill
    // the header and send the slice.
    pub fn sendJSON(self: *WsConnection, message: anytype, opts: std.json.Stringify.Options) !void {
        const allocator = self.send_arena.allocator();

        var aw = try std.Io.Writer.Allocating.initCapacity(allocator, 512);

        // reserve space for the maximum possible header
        try aw.writer.writeAll(&.{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 });
        try std.json.Stringify.value(message, opts, &aw.writer);
        const framed = fillWebsocketHeader(aw.toArrayList());
        return self.send(framed);
    }

    pub fn sendJSONRaw(
        self: *WsConnection,
        buf: std.ArrayList(u8),
    ) !void {
        // Dangerous API!. We assume the caller has reserved the first 10
        // bytes in `buf`.
        const framed = fillWebsocketHeader(buf);
        return self.send(framed);
    }

    pub fn read(self: *WsConnection) !usize {
        const n = try posix.recv(self.socket, self.reader.readBuf(), 0);
        self.reader.len += n;
        return n;
    }

    pub fn processMessages(self: *WsConnection, handler: anytype) !bool {
        var reader = &self.reader;
        while (true) {
            const msg = reader.next() catch |err| {
                switch (err) {
                    error.TooLarge => self.send(&CLOSE_TOO_BIG) catch {},
                    error.NotMasked => self.send(&CLOSE_PROTOCOL_ERROR) catch {},
                    error.ReservedFlags => self.send(&CLOSE_PROTOCOL_ERROR) catch {},
                    error.InvalidMessageType => self.send(&CLOSE_PROTOCOL_ERROR) catch {},
                    error.ControlTooLarge => self.send(&CLOSE_PROTOCOL_ERROR) catch {},
                    error.InvalidContinuation => self.send(&CLOSE_PROTOCOL_ERROR) catch {},
                    error.NestedFragementation => self.send(&CLOSE_PROTOCOL_ERROR) catch {},
                    error.OutOfMemory => {}, // don't borther trying to send an error in this case
                }
                return err;
            } orelse break;

            switch (msg.type) {
                .pong => {},
                .ping => try self.sendPong(msg.data),
                .close => {
                    self.send(&CLOSE_NORMAL) catch {};
                    return false;
                },
                .text, .binary => if (handler.handleMessage(msg.data) == false) {
                    return false;
                },
            }
            if (msg.cleanup_fragment) {
                reader.cleanup();
            }
        }

        // We might have read part of the next message. Our reader potentially
        // has to move data around in its buffer to make space.
        reader.compact();
        return true;
    }

    pub fn upgrade(self: *WsConnection, request: []u8) !void {
        // our caller already confirmed that we have a trailing \r\n\r\n
        const request_line_end = std.mem.indexOfScalar(u8, request, '\r') orelse unreachable;
        const request_line = request[0..request_line_end];

        if (!std.ascii.endsWithIgnoreCase(request_line, "http/1.1")) {
            return error.InvalidProtocol;
        }

        // we need to extract the sec-websocket-key value
        var key: []const u8 = "";

        // we need to make sure that we got all the necessary headers + values
        var required_headers: u8 = 0;

        // can't std.mem.split because it forces the iterated value to be const
        // (we could @constCast...)

        var buf = request[request_line_end + 2 ..];

        while (buf.len > 4) {
            const index = std.mem.indexOfScalar(u8, buf, '\r') orelse unreachable;
            const separator = std.mem.indexOfScalar(u8, buf[0..index], ':') orelse return error.InvalidRequest;

            const name = std.mem.trim(u8, toLower(buf[0..separator]), &std.ascii.whitespace);
            const value = std.mem.trim(u8, buf[(separator + 1)..index], &std.ascii.whitespace);

            if (std.mem.eql(u8, name, "upgrade")) {
                if (!std.ascii.eqlIgnoreCase("websocket", value)) {
                    return error.InvalidUpgradeHeader;
                }
                required_headers |= 1;
            } else if (std.mem.eql(u8, name, "sec-websocket-version")) {
                if (value.len != 2 or value[0] != '1' or value[1] != '3') {
                    return error.InvalidVersionHeader;
                }
                required_headers |= 2;
            } else if (std.mem.eql(u8, name, "connection")) {
                // find if connection header has upgrade in it, example header:
                // Connection: keep-alive, Upgrade
                if (std.ascii.indexOfIgnoreCase(value, "upgrade") == null) {
                    return error.InvalidConnectionHeader;
                }
                required_headers |= 4;
            } else if (std.mem.eql(u8, name, "sec-websocket-key")) {
                key = value;
                required_headers |= 8;
            }

            const next = index + 2;
            buf = buf[next..];
        }

        if (required_headers != 15) {
            return error.MissingHeaders;
        }

        // our caller has already made sure this request ended in \r\n\r\n
        // so it isn't something we need to check again

        const alloc = self.send_arena.allocator();

        const response = blk: {
            // Response to an ugprade request is always this, with
            // the Sec-Websocket-Accept value a spacial sha1 hash of the
            // request "sec-websocket-version" and a magic value.

            const template =
                "HTTP/1.1 101 Switching Protocols\r\n" ++
                "Upgrade: websocket\r\n" ++
                "Connection: upgrade\r\n" ++
                "Sec-Websocket-Accept: 0000000000000000000000000000\r\n\r\n";

            // The response will be sent via the IO Loop and thus has to have its
            // own lifetime.
            const res = try alloc.dupe(u8, template);

            // magic response
            const key_pos = res.len - 32;
            var h: [20]u8 = undefined;
            var hasher = std.crypto.hash.Sha1.init(.{});
            hasher.update(key);
            // websocket spec always used this value
            hasher.update("258EAFA5-E914-47DA-95CA-C5AB0DC85B11");
            hasher.final(&h);

            _ = std.base64.standard.Encoder.encode(res[key_pos .. key_pos + 28], h[0..]);

            break :blk res;
        };

        return self.send(response);
    }

    pub fn sendHttpError(self: *WsConnection, comptime status: u16, comptime body: []const u8) void {
        const response = std.fmt.comptimePrint(
            "HTTP/1.1 {d} \r\nConnection: Close\r\nContent-Length: {d}\r\n\r\n{s}",
            .{ status, body.len, body },
        );

        // we're going to close this connection anyways, swallowing any
        // error seems safe
        self.send(response) catch {};
    }

    pub fn getAddress(self: *WsConnection) !std.net.Address {
        var address: std.net.Address = undefined;
        var socklen: posix.socklen_t = @sizeOf(std.net.Address);
        try posix.getpeername(self.socket, &address.any, &socklen);
        return address;
    }

    pub fn shutdown(self: *WsConnection) void {
        posix.shutdown(self.socket, .recv) catch {};
    }

    pub fn setBlocking(self: *WsConnection, blocking: bool) !void {
        if (comptime builtin.os.tag == .windows) {
            return;
        }

        if (blocking) {
            _ = try posix.fcntl(self.socket, posix.F.SETFL, self.socket_flags & ~@as(u32, @bitCast(posix.O{ .NONBLOCK = true })));
        } else {
            _ = try posix.fcntl(self.socket, posix.F.SETFL, self.socket_flags);
        }
    }
};

const testing = std.testing;

test "mask" {
    var buf: [4000]u8 = undefined;
    const messages = [_][]const u8{ "1234", "1234"**99, "1234"**999 };
    for (messages) |message| {
        // we need the message to be mutable since mask operates in-place
        const payload = buf[0..message.len];
        @memcpy(payload, message);

        mask(&.{ 1, 2, 200, 240 }, payload);
        try testing.expectEqual(false, std.mem.eql(u8, payload, message));

        mask(&.{ 1, 2, 200, 240 }, payload);
        try testing.expectEqual(true, std.mem.eql(u8, payload, message));
    }
}
