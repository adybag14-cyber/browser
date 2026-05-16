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
const js = @import("../js/js.zig");
const Page = @import("../Page.zig");
const EventTarget = @import("EventTarget.zig");
const testing = @import("../../testing.zig");

pub fn registerTypes() []const type {
    return &.{
        Screen,
        Orientation,
    };
}

const Screen = @This();

_proto: *EventTarget,
_orientation: ?*Orientation = null,
_width: u32 = 1920,
_height: u32 = 1080,
_avail_height: u32 = 1040,

pub fn setDimensions(self: *Screen, width: u32, height: u32) void {
    self._width = if (width == 0) 1 else width;
    self._height = if (height == 0) 1 else height;
    self._avail_height = if (self._height > 40) self._height - 40 else self._height;
}

pub fn getWidth(self: *const Screen) u32 {
    return self._width;
}

pub fn getHeight(self: *const Screen) u32 {
    return self._height;
}

pub fn getAvailWidth(self: *const Screen) u32 {
    return self._width;
}

pub fn getAvailHeight(self: *const Screen) u32 {
    return self._avail_height;
}

pub fn getAvailLeft(_: *const Screen) i32 {
    return 0;
}

pub fn getAvailTop(_: *const Screen) i32 {
    return 0;
}

pub fn getIsExtended(_: *const Screen) bool {
    return false;
}

pub fn asEventTarget(self: *Screen) *EventTarget {
    return self._proto;
}

pub fn getOrientation(self: *Screen, page: *Page) !*Orientation {
    if (self._orientation) |orientation| {
        return orientation;
    }
    const orientation = try Orientation.init(page, self);
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
    pub const availLeft = bridge.accessor(Screen.getAvailLeft, null, .{});
    pub const availTop = bridge.accessor(Screen.getAvailTop, null, .{});
    pub const colorDepth = bridge.property(24, .{ .template = false });
    pub const pixelDepth = bridge.property(24, .{ .template = false });
    pub const isExtended = bridge.accessor(Screen.getIsExtended, null, .{});
    pub const orientation = bridge.accessor(Screen.getOrientation, null, .{});
};

pub const Orientation = struct {
    _proto: *EventTarget,
    _screen: *Screen,

    pub fn init(page: *Page, screen: *Screen) !*Orientation {
        return page._factory.eventTarget(Orientation{
            ._proto = undefined,
            ._screen = screen,
        });
    }

    pub fn asEventTarget(self: *Orientation) *EventTarget {
        return self._proto;
    }

    pub fn getAngle(_: *const Orientation) u32 {
        return 0;
    }

    pub fn getType(self: *const Orientation) []const u8 {
        if (self._screen.getHeight() > self._screen.getWidth()) {
            return "portrait-primary";
        }
        return "landscape-primary";
    }

    pub const JsApi = struct {
        pub const bridge = js.Bridge(Orientation);

        pub const Meta = struct {
            pub const name = "ScreenOrientation";
            pub const prototype_chain = bridge.prototypeChain();
            pub var class_id: bridge.ClassId = undefined;
        };

        pub const angle = bridge.accessor(Orientation.getAngle, null, .{});
        pub const @"type" = bridge.accessor(Orientation.getType, null, .{});
    };
};

test "ScreenOrientation type tracks dimensions" {
    var screen = Screen{
        ._proto = undefined,
    };
    var orientation = Orientation{
        ._proto = undefined,
        ._screen = &screen,
    };

    try std.testing.expectEqualStrings("landscape-primary", orientation.getType());
    screen.setDimensions(600, 900);
    try std.testing.expectEqualStrings("portrait-primary", orientation.getType());
    screen.setDimensions(900, 600);
    try std.testing.expectEqualStrings("landscape-primary", orientation.getType());
}

test "WebApi: Screen" {
    try testing.htmlRunner("screen.html", .{});
}
