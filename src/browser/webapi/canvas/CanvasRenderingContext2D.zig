// Copyright (C) 2023-2025  Lightpanda (Selecy SAS)
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

const js = @import("../../js/js.zig");

const color = @import("../../color.zig");

const Canvas = @import("../element/html/Canvas.zig");
const ImageData = @import("../ImageData.zig");
const CanvasSurface = @import("CanvasSurface.zig");
const CanvasPath = @import("CanvasPath.zig");
const Canvas = @import("../element/html/Canvas.zig");
const OffscreenCanvas = @import("OffscreenCanvas.zig");
const Image = @import("../element/html/Image.zig");

const Execution = js.Execution;

/// This class doesn't implement a `constructor`.
/// It can be obtained with a call to `HTMLCanvasElement#getContext`.
/// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D
const CanvasRenderingContext2D = @This();
/// Reference to the parent canvas element.
/// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/canvas
_canvas: *Canvas,
/// Fill color.
/// TODO: Add support for `CanvasGradient` and `CanvasPattern`.
_fill_style: color.RGBA = color.RGBA.Named.black,
_stroke_style: color.RGBA = color.RGBA.Named.black,
_allocator: std.mem.Allocator,
_path: CanvasPath = .{},
_surface: *CanvasSurface,

pub fn getCanvas(self: *const CanvasRenderingContext2D) *Canvas {
    return self._canvas;
}

pub fn getFillStyle(self: *const CanvasRenderingContext2D, exec: *Execution) ![]const u8 {
    var w = std.Io.Writer.Allocating.init(exec.local_arena);
    try self._fill_style.format(&w.writer);
    return w.written();
}

pub fn setFillStyle(
    self: *CanvasRenderingContext2D,
    value: []const u8,
) !void {
    // Prefer the same fill_style if fails.
    self._fill_style = color.RGBA.parse(value) catch self._fill_style;
}

pub fn getStrokeStyle(self: *const CanvasRenderingContext2D, page: *Page) ![]const u8 {
    var w = std.Io.Writer.Allocating.init(page.call_arena);
    try self._stroke_style.format(&w.writer);
    return w.written();
}

pub fn setStrokeStyle(self: *CanvasRenderingContext2D, value: []const u8) void {
    self._stroke_style = color.RGBA.parse(value) catch self._stroke_style;
}

const WidthOrImageData = union(enum) {
    width: u32,
    image_data: *ImageData,
};

const DrawImageSource = union(enum) {
    canvas: *Canvas,
    offscreen_canvas: *OffscreenCanvas,
    image: *Image,
};

pub fn createImageData(
    _: *const CanvasRenderingContext2D,
    width_or_image_data: WidthOrImageData,
    /// If `ImageData` variant preferred, this is null.
    maybe_height: ?u32,
    /// Can be used if width and height provided.
    maybe_settings: ?ImageData.ConstructorSettings,
    exec: *Execution,
) !*ImageData {
    switch (width_or_image_data) {
        .width => |width| {
            const height = maybe_height orelse return error.TypeError;
            return ImageData.init(width, height, maybe_settings, exec);
        },
        .image_data => |image_data| {
            return ImageData.init(image_data._width, image_data._height, null, exec);
        },
    }
}

pub fn putImageData(_: *const CanvasRenderingContext2D, _: *ImageData, _: f64, _: f64, _: ?f64, _: ?f64, _: ?f64, _: ?f64) void {}

// CanvasImageSource (HTMLImageElement, HTMLCanvasElement, ImageBitmap, ...) is
// just taken as a js.Value for now since we don't use it, and that's much easier.
pub fn drawImage(_: *const CanvasRenderingContext2D, _: js.Value, _: f64, _: f64, _: ?f64, _: ?f64, _: ?f64, _: ?f64, _: ?f64, _: ?f64) void {}

pub fn getImageData(
    _: *const CanvasRenderingContext2D,
    _: i32, // sx
    _: i32, // sy
    sw: i32,
    sh: i32,
    exec: *Execution,
) !*ImageData {
    if (sw <= 0 or sh <= 0) {
        return error.IndexSizeError;
    }
    return ImageData.init(@intCast(sw), @intCast(sh), null, exec);
}

pub fn save(_: *CanvasRenderingContext2D) void {}
pub fn restore(_: *CanvasRenderingContext2D) void {}
pub fn scale(_: *CanvasRenderingContext2D, _: f64, _: f64) void {}
pub fn rotate(_: *CanvasRenderingContext2D, _: f64) void {}
pub fn translate(_: *CanvasRenderingContext2D, _: f64, _: f64) void {}
pub fn transform(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64, _: f64, _: f64) void {}
pub fn setTransform(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64, _: f64, _: f64) void {}
pub fn resetTransform(_: *CanvasRenderingContext2D) void {}
pub fn clearRect(self: *CanvasRenderingContext2D, x: f64, y: f64, width: f64, height: f64) void {
    self._surface.clearRect(x, y, width, height);
}
pub fn fillRect(self: *CanvasRenderingContext2D, x: f64, y: f64, width: f64, height: f64) void {
    self._surface.fillRect(self._fill_style, x, y, width, height);
}
pub fn strokeRect(self: *CanvasRenderingContext2D, x: f64, y: f64, width: f64, height: f64) void {
    self._surface.strokeRect(self._stroke_style, x, y, width, height);
}
pub fn beginPath(self: *CanvasRenderingContext2D) void {
    self._path.beginPath();
}
pub fn closePath(self: *CanvasRenderingContext2D) void {
    self._path.closePath();
}
pub fn moveTo(self: *CanvasRenderingContext2D, x: f64, y: f64) void {
    self._path.moveTo(self._allocator, x, y) catch {};
}
pub fn lineTo(self: *CanvasRenderingContext2D, x: f64, y: f64) void {
    self._path.lineTo(self._allocator, x, y) catch {};
}
pub fn quadraticCurveTo(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64) void {}
pub fn bezierCurveTo(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64, _: f64, _: f64) void {}
pub fn arc(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64, _: f64, _: ?bool) void {}
pub fn arcTo(_: *CanvasRenderingContext2D, _: f64, _: f64, _: f64, _: f64, _: f64) void {}
pub fn rect(self: *CanvasRenderingContext2D, x: f64, y: f64, width: f64, height: f64) void {
    self._path.rect(self._allocator, x, y, width, height) catch {};
}
pub fn fill(self: *CanvasRenderingContext2D) void {
    self._path.fill(self._allocator, self._surface, self._fill_style) catch {};
}
pub fn stroke(self: *CanvasRenderingContext2D) void {
    self._path.stroke(self._surface, self._stroke_style);
}
pub fn clip(_: *CanvasRenderingContext2D) void {}
pub fn fillText(_: *CanvasRenderingContext2D, _: []const u8, _: f64, _: f64, _: ?f64) void {}
pub fn strokeText(_: *CanvasRenderingContext2D, _: []const u8, _: f64, _: f64, _: ?f64) void {}

const SourceSurface = struct {
    surface: *const CanvasSurface,
    width: u32,
    height: u32,
};

fn sourceSurface(source: DrawImageSource, page: *Page) !?SourceSurface {
    return switch (source) {
        .canvas => |canvas| blk: {
            const surface = canvas.getSurface() orelse break :blk null;
            break :blk .{
                .surface = surface,
                .width = canvas.getWidth(),
                .height = canvas.getHeight(),
            };
        },
        .offscreen_canvas => |canvas| blk: {
            const surface = canvas.getSurface() orelse break :blk null;
            break :blk .{
                .surface = surface,
                .width = canvas.getWidth(),
                .height = canvas.getHeight(),
            };
        },
        .image => |image| blk: {
            const surface = image.getCanvasSurface(page) orelse break :blk null;
            break :blk .{
                .surface = surface,
                .width = image.getNaturalWidth(page),
                .height = image.getNaturalHeight(page),
            };
        },
    };
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(CanvasRenderingContext2D);

    pub const Meta = struct {
        pub const name = "CanvasRenderingContext2D";

        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const canvas = bridge.accessor(CanvasRenderingContext2D.getCanvas, null, .{});
    pub const font = bridge.property("10px sans-serif", .{ .template = false, .readonly = false });
    pub const globalAlpha = bridge.property(1.0, .{ .template = false, .readonly = false });
    pub const globalCompositeOperation = bridge.property("source-over", .{ .template = false, .readonly = false });
    pub const strokeStyle = bridge.accessor(CanvasRenderingContext2D.getStrokeStyle, CanvasRenderingContext2D.setStrokeStyle, .{});
    pub const lineWidth = bridge.property(1.0, .{ .template = false, .readonly = false });
    pub const lineCap = bridge.property("butt", .{ .template = false, .readonly = false });
    pub const lineJoin = bridge.property("miter", .{ .template = false, .readonly = false });
    pub const miterLimit = bridge.property(10.0, .{ .template = false, .readonly = false });
    pub const textAlign = bridge.property("start", .{ .template = false, .readonly = false });
    pub const textBaseline = bridge.property("alphabetic", .{ .template = false, .readonly = false });

    pub const fillStyle = bridge.accessor(CanvasRenderingContext2D.getFillStyle, CanvasRenderingContext2D.setFillStyle, .{});
    pub const createImageData = bridge.function(CanvasRenderingContext2D.createImageData, .{});

    pub const putImageData = bridge.function(CanvasRenderingContext2D.putImageData, .{ .noop = true });
    pub const drawImage = bridge.function(CanvasRenderingContext2D.drawImage, .{ .noop = true });
    pub const getImageData = bridge.function(CanvasRenderingContext2D.getImageData, .{});
    pub const save = bridge.function(CanvasRenderingContext2D.save, .{ .noop = true });
    pub const restore = bridge.function(CanvasRenderingContext2D.restore, .{ .noop = true });
    pub const scale = bridge.function(CanvasRenderingContext2D.scale, .{ .noop = true });
    pub const rotate = bridge.function(CanvasRenderingContext2D.rotate, .{ .noop = true });
    pub const translate = bridge.function(CanvasRenderingContext2D.translate, .{ .noop = true });
    pub const transform = bridge.function(CanvasRenderingContext2D.transform, .{ .noop = true });
    pub const setTransform = bridge.function(CanvasRenderingContext2D.setTransform, .{ .noop = true });
    pub const resetTransform = bridge.function(CanvasRenderingContext2D.resetTransform, .{ .noop = true });
    pub const clearRect = bridge.function(CanvasRenderingContext2D.clearRect, .{});
    pub const fillRect = bridge.function(CanvasRenderingContext2D.fillRect, .{});
    pub const strokeRect = bridge.function(CanvasRenderingContext2D.strokeRect, .{});
    pub const beginPath = bridge.function(CanvasRenderingContext2D.beginPath, .{});
    pub const closePath = bridge.function(CanvasRenderingContext2D.closePath, .{});
    pub const moveTo = bridge.function(CanvasRenderingContext2D.moveTo, .{});
    pub const lineTo = bridge.function(CanvasRenderingContext2D.lineTo, .{});
    pub const quadraticCurveTo = bridge.function(CanvasRenderingContext2D.quadraticCurveTo, .{ .noop = true });
    pub const bezierCurveTo = bridge.function(CanvasRenderingContext2D.bezierCurveTo, .{ .noop = true });
    pub const arc = bridge.function(CanvasRenderingContext2D.arc, .{ .noop = true });
    pub const arcTo = bridge.function(CanvasRenderingContext2D.arcTo, .{ .noop = true });
    pub const rect = bridge.function(CanvasRenderingContext2D.rect, .{});
    pub const fill = bridge.function(CanvasRenderingContext2D.fill, .{});
    pub const stroke = bridge.function(CanvasRenderingContext2D.stroke, .{});
    pub const clip = bridge.function(CanvasRenderingContext2D.clip, .{ .noop = true });
    pub const fillText = bridge.function(CanvasRenderingContext2D.fillText, .{ .noop = true });
    pub const strokeText = bridge.function(CanvasRenderingContext2D.strokeText, .{ .noop = true });
};

const testing = @import("../../../testing.zig");
test "WebApi: CanvasRenderingContext2D" {
    try testing.htmlRunner("canvas/canvas_rendering_context_2d.html", .{});
}
