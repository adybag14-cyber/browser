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

const builtin = @import("builtin");
const js = @import("../js/js.zig");
const Page = @import("../Page.zig");
const EventTarget = @import("EventTarget.zig");
const win = if (builtin.os.tag == .windows) @import("win32_c") else struct {};

pub fn registerTypes() []const type {
    return &.{
        Screen,
        Orientation,
    };
}

const Screen = @This();

const fallback_width: u32 = 1920;
const fallback_height: u32 = 1080;
const fallback_avail_height: u32 = 1040;

const Dimensions = struct {
    width: u32 = fallback_width,
    height: u32 = fallback_height,
    avail_width: u32 = fallback_width,
    avail_height: u32 = fallback_avail_height,
};

_proto: *EventTarget,
_orientation: ?*Orientation = null,
_width: u32 = fallback_width,
_height: u32 = fallback_height,
_avail_width: u32 = fallback_width,
_avail_height: u32 = fallback_avail_height,

pub fn initDefault() Screen {
    const dimensions = defaultDimensions();
    return .{
        ._proto = undefined,
        ._orientation = null,
        ._width = dimensions.width,
        ._height = dimensions.height,
        ._avail_width = dimensions.avail_width,
        ._avail_height = dimensions.avail_height,
    };
}

fn defaultDimensions() Dimensions {
    if (comptime builtin.os.tag == .windows) {
        const width = positiveMetric(win.GetSystemMetrics(win.SM_CXSCREEN), fallback_width);
        const height = positiveMetric(win.GetSystemMetrics(win.SM_CYSCREEN), fallback_height);
        const avail_width = clampToMetric(
            positiveMetric(win.GetSystemMetrics(win.SM_CXFULLSCREEN), width),
            width,
        );
        const avail_height = clampToMetric(
            positiveMetric(win.GetSystemMetrics(win.SM_CYFULLSCREEN), if (height > 40) height - 40 else height),
            height,
        );

        return .{
            .width = width,
            .height = height,
            .avail_width = avail_width,
            .avail_height = avail_height,
        };
    }

    return .{};
}

fn positiveMetric(value: c_int, fallback: u32) u32 {
    if (value <= 0) return fallback;
    return @intCast(value);
}

fn clampToMetric(value: u32, maximum: u32) u32 {
    if (maximum == 0) return value;
    return @min(value, maximum);
}

pub fn setDimensions(self: *Screen, width: u32, height: u32) void {
    self._width = if (width == 0) 1 else width;
    self._height = if (height == 0) 1 else height;
    self._avail_width = self._width;
    self._avail_height = if (self._height > 40) self._height - 40 else self._height;
}

pub fn getWidth(self: *const Screen) u32 {
    return self._width;
}

pub fn getHeight(self: *const Screen) u32 {
    return self._height;
}

pub fn getAvailWidth(self: *const Screen) u32 {
    return self._avail_width;
}

pub fn getAvailHeight(self: *const Screen) u32 {
    return self._avail_height;
}

pub fn asEventTarget(self: *Screen) *EventTarget {
    return self._proto;
}

pub fn getOrientation(self: *Screen, page: *Page) !*Orientation {
    if (self._orientation) |orientation| {
        return orientation;
    }
    const orientation = try Orientation.init(page);
    self._orientation = orientation;
    return orientation;
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(Screen);

    pub const Meta = struct {
        pub const name = "Screen";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const width = bridge.accessor(Screen.getWidth, null, .{});
    pub const height = bridge.accessor(Screen.getHeight, null, .{});
    pub const availWidth = bridge.accessor(Screen.getAvailWidth, null, .{});
    pub const availHeight = bridge.accessor(Screen.getAvailHeight, null, .{});
    pub const colorDepth = bridge.property(32, .{ .template = false });
    pub const pixelDepth = bridge.property(32, .{ .template = false });
    pub const orientation = bridge.accessor(Screen.getOrientation, null, .{});
};

pub const Orientation = struct {
    _proto: *EventTarget,

    pub fn init(page: *Page) !*Orientation {
        return page._factory.eventTarget(Orientation{
            ._proto = undefined,
        });
    }

    pub fn asEventTarget(self: *Orientation) *EventTarget {
        return self._proto;
    }

    pub const JsApi = struct {
        pub const bridge = js.Bridge(Orientation);

        pub const Meta = struct {
            pub const name = "ScreenOrientation";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const angle = bridge.property(0, .{ .template = false });
        pub const @"type" = bridge.property("landscape-primary", .{ .template = false });
    };
};
