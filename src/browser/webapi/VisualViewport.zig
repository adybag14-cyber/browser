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

const js = @import("../js/js.zig");
const Frame = @import("../Frame.zig");
const EventTarget = @import("EventTarget.zig");

const VisualViewport = @This();

pub const Proto = EventTarget;

_proto: *EventTarget,
_width: u32 = 1920,
_height: u32 = 1080,
_scale: f64 = 1.0,

pub fn setMetrics(self: *VisualViewport, width: u32, height: u32, scale: f64) void {
    self._width = if (width == 0) 1 else width;
    self._height = if (height == 0) 1 else height;
    self._scale = if (scale <= 0) 1.0 else scale;
}

pub fn asEventTarget(self: *VisualViewport) *EventTarget {
    return self._proto;
}

pub fn getPageLeft(_: *const VisualViewport, frame: *Frame) u32 {
    return frame.window.getScrollX();
}

pub fn getPageTop(_: *const VisualViewport, frame: *Frame) u32 {
    return frame.window.getScrollY();
}

pub fn getWidth(_: *const VisualViewport, frame: *Frame) u32 {
    return frame._page.getViewport().width;
}

pub fn getHeight(_: *const VisualViewport, frame: *Frame) u32 {
    return frame._page.getViewport().height;
}

pub fn getWidth(self: *const VisualViewport) u32 {
    return self._width;
}

pub fn getHeight(self: *const VisualViewport) u32 {
    return self._height;
}

pub fn getScale(self: *const VisualViewport) f64 {
    return self._scale;
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(VisualViewport);

    pub const Meta = struct {
        pub const name = "VisualViewport";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    // Viewport properties are static for a given page instance today.
    // They are sourced from runtime browser configuration.
    pub const offsetLeft = bridge.property(0, .{ .template = false });
    pub const offsetTop = bridge.property(0, .{ .template = false });
    pub const pageLeft = bridge.accessor(VisualViewport.getPageLeft, null, .{});
    pub const pageTop = bridge.accessor(VisualViewport.getPageTop, null, .{});
    pub const width = bridge.accessor(VisualViewport.getWidth, null, .{});
    pub const height = bridge.accessor(VisualViewport.getHeight, null, .{});
    pub const scale = bridge.property(1.0, .{ .template = false });
};
