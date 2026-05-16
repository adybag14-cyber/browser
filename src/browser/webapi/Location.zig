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

const URL = @import("URL.zig");
const Page = @import("../Page.zig");

const Location = @This();

_url: *URL,

pub fn init(raw_url: [:0]const u8, page: *Page) !*Location {
    const url = try URL.init(raw_url, null, page);
    return page._factory.create(Location{
        ._url = url,
    });
}

pub fn getPathname(self: *const Location) []const u8 {
    return self._url.getPathname();
}

pub fn getProtocol(self: *const Location) []const u8 {
    return self._url.getProtocol();
}

pub fn getHostname(self: *const Location) []const u8 {
    return self._url.getHostname();
}

pub fn getHost(self: *const Location) []const u8 {
    return self._url.getHost();
}

pub fn getPort(self: *const Location) []const u8 {
    return self._url.getPort();
}

pub fn getOrigin(self: *const Location, page: *const Page) ![]const u8 {
    return self._url.getOrigin(page);
}

pub fn getSearch(self: *const Location, page: *const Page) ![]const u8 {
    return self._url.getSearch(page);
}

pub fn getHash(self: *const Location) []const u8 {
    return self._url.getHash();
}

pub fn setHash(_: *const Location, hash: []const u8, page: *Page) !void {
    const normalized_hash = blk: {
        if (hash.len == 0) {
            const old_url = page.url;

            break :blk if (std.mem.indexOfScalar(u8, old_url, '#')) |index|
                old_url[0..index]
            else
                old_url;
        } else if (hash[0] == '#')
            break :blk hash
        else
            break :blk try std.fmt.allocPrint(page.call_arena, "#{s}", .{hash});
    };

    return page.scheduleNavigation(normalized_hash, .{
        .reason = .script,
        .kind = .{ .replace = null },
    }, .{ .script = page });
}

fn navigateToCurrent(self: *const Location, page: *Page) !void {
    const target = try self.toString(page);
    return page.scheduleNavigation(target, .{ .reason = .script, .kind = .{ .push = null } }, .{ .script = page });
}

pub fn setSearch(self: *const Location, search: []const u8, page: *Page) !void {
    try self._url.setSearch(search, page);
    return self.navigateToCurrent(page);
}

pub fn setPathname(self: *const Location, pathname: []const u8, page: *Page) !void {
    try self._url.setPathname(pathname);
    return self.navigateToCurrent(page);
}

pub fn setProtocol(self: *const Location, protocol: []const u8, page: *Page) !void {
    try self._url.setProtocol(protocol);
    return self.navigateToCurrent(page);
}

pub fn setHostname(self: *const Location, hostname: []const u8, page: *Page) !void {
    try self._url.setHostname(hostname);
    return self.navigateToCurrent(page);
}

pub fn setHost(self: *const Location, host: []const u8, page: *Page) !void {
    try self._url.setHost(host);
    return self.navigateToCurrent(page);
}

pub fn setPort(self: *const Location, port: []const u8, page: *Page) !void {
    try self._url.setPort(if (port.len == 0) null else port);
    return self.navigateToCurrent(page);
}

pub fn assign(_: *const Location, url: [:0]const u8, page: *Page) !void {
    return page.scheduleNavigation(url, .{ .reason = .script, .kind = .{ .push = null } }, .{ .script = page });
}

pub fn replace(_: *const Location, url: [:0]const u8, page: *Page) !void {
    return page.scheduleNavigation(url, .{ .reason = .script, .kind = .{ .replace = null } }, .{ .script = page });
}

pub fn reload(_: *const Location, page: *Page) !void {
    return page.scheduleNavigation(page.url, .{ .reason = .script, .kind = .reload }, .{ .script = page });
}

pub fn toString(self: *const Location, page: *const Page) ![:0]const u8 {
    return self._url.toString(page);
}

pub const JsApi = struct {
    pub const bridge = js.Bridge(Location);

    pub const Meta = struct {
        pub const name = "Location";
        pub const prototype_chain = bridge.prototypeChain();
        pub var class_id: bridge.ClassId = undefined;
    };

    pub const toString = bridge.function(Location.toString, .{});
    pub const href = bridge.accessor(Location.toString, setHref, .{});
    fn setHref(self: *const Location, url: [:0]const u8, page: *Page) !void {
        return self.assign(url, page);
    }

    pub const search = bridge.accessor(Location.getSearch, Location.setSearch, .{});
    pub const hash = bridge.accessor(Location.getHash, Location.setHash, .{});
    pub const pathname = bridge.accessor(Location.getPathname, Location.setPathname, .{});
    pub const hostname = bridge.accessor(Location.getHostname, Location.setHostname, .{});
    pub const host = bridge.accessor(Location.getHost, Location.setHost, .{});
    pub const port = bridge.accessor(Location.getPort, Location.setPort, .{});
    pub const origin = bridge.accessor(Location.getOrigin, null, .{});
    pub const protocol = bridge.accessor(Location.getProtocol, Location.setProtocol, .{});
    pub const assign = bridge.function(Location.assign, .{});
    pub const replace = bridge.function(Location.replace, .{});
    pub const reload = bridge.function(Location.reload, .{});
};

const testing = @import("../../testing.zig");

test "Location search setter queues script navigation with updated query" {
    var page = try testing.pageTest("page/rendered_link_activation.html");
    defer page._session.removePage();

    page.url = "https://www.google.com/search?q=openai&gbv=1";
    page.window._location = try Location.init(page.url, &page);
    page.document._location = page.window._location;

    try page.window._location.setSearch("?q=openai&gbv=2&sg_ss=abc", &page);

    const queued = page._queued_navigation orelse return error.ExpectedQueuedNavigation;
    try std.testing.expectEqualStrings(
        "https://www.google.com/search?q=openai&gbv=2&sg_ss=abc",
        queued.url,
    );
    try std.testing.expectEqual(.script, queued.navigation_type);
}
