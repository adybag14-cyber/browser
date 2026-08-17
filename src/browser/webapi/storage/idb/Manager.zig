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

const Engine = @import("Engine.zig");

const Allocator = std.mem.Allocator;

const Manager = @This();

allocator: Allocator,
engines: std.StringHashMapUnmanaged(*Engine) = .empty,
storage_dir: ?[]u8 = null,

pub fn init(allocator: Allocator) Manager {
    return .{ .allocator = allocator };
}

pub fn initPersistent(allocator: Allocator, storage_dir: []const u8) !Manager {
    return .{
        .allocator = allocator,
        .storage_dir = try allocator.dupe(u8, storage_dir),
    };
}

pub fn deinit(self: *Manager) void {
    var it = self.engines.iterator();
    while (it.next()) |kv| {
        kv.value_ptr.*.close();
        self.allocator.destroy(kv.value_ptr.*);
        self.allocator.free(kv.key_ptr.*);
    }
    self.engines.deinit(self.allocator);
    if (self.storage_dir) |storage_dir| self.allocator.free(storage_dir);
    self.* = undefined;
}

// A js Context is being torn down (navigation, popup close, worker close):
// every engine must drop any gate participant whose callbacks would run in it.
// Must be called before that context's scheduler is reset or deinit'd.
pub fn detachContext(self: *Manager, ctx: *anyopaque) void {
    var it = self.engines.valueIterator();
    while (it.next()) |engine| {
        engine.*.detach(ctx);
    }
}

// Gets or creates the engine for the given origin.
pub fn engineForOrigin(self: *Manager, origin: []const u8) !*Engine {
    const gop = try self.engines.getOrPut(self.allocator, origin);
    if (gop.found_existing) {
        return gop.value_ptr.*;
    }
    errdefer _ = self.engines.remove(origin);

    const engine = try self.allocator.create(Engine);
    errdefer self.allocator.destroy(engine);

    const engine_path: [:0]const u8 = if (self.storage_dir) |storage_dir| blk: {
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(origin, &digest, .{});
        const alphabet = "0123456789abcdef";
        var hex: [digest.len * 2]u8 = undefined;
        for (digest, 0..) |byte, index| {
            hex[index * 2] = alphabet[byte >> 4];
            hex[index * 2 + 1] = alphabet[byte & 0x0f];
        }
        const filename = try std.fmt.allocPrint(self.allocator, "origin-{s}.sqlite", .{hex[0..]});
        defer self.allocator.free(filename);
        const path = try std.fs.path.join(self.allocator, &.{ storage_dir, filename });
        defer self.allocator.free(path);
        break :blk try self.allocator.dupeZ(u8, path);
    } else ":memory:";
    defer if (self.storage_dir != null) self.allocator.free(engine_path);

    engine.* = try Engine.open(engine_path);
    errdefer engine.close();

    gop.key_ptr.* = try self.allocator.dupe(u8, origin);
    gop.value_ptr.* = engine;
    return engine;
}

const testing = @import("../../../../testing.zig");
test "IDB - Manager: same origin returns same engine, distinct origins differ" {
    var mgr = Manager.init(testing.allocator);
    defer mgr.deinit();

    const a1 = try mgr.engineForOrigin("https://a.com");
    const a2 = try mgr.engineForOrigin("https://a.com");
    const b1 = try mgr.engineForOrigin("https://b.com");

    try testing.expect(a1 == a2);
    try testing.expect(a1 != b1);
}

test "IDB - Manager: in-memory engines are origin-isolated" {
    var mgr = Manager.init(testing.allocator);
    defer mgr.deinit();

    const a = try mgr.engineForOrigin("https://a.com");
    const b = try mgr.engineForOrigin("https://b.com");

    _ = try a.upsertDatabase("db", 1);
    try testing.expectEqual(null, try b.databaseVersion("db"));
}

test "IDB - Manager: persistent engines survive restart and remain origin-isolated" {
    const rel_dir = ".zig-cache/tmp/idb-manager-persistent-test";
    const cwd = std.Io.Dir.cwd();
    cwd.deleteTree(testing.io, rel_dir) catch {};
    try cwd.createDirPath(testing.io, rel_dir);
    defer cwd.deleteTree(testing.io, rel_dir) catch {};
    const abs_dir = try cwd.realPathFileAlloc(testing.io, rel_dir, testing.allocator);
    defer testing.allocator.free(abs_dir);

    const long_host = "https://" ++ ("a" ** 250) ++ ".com";
    {
        var mgr = try Manager.initPersistent(testing.allocator, abs_dir);
        defer mgr.deinit();
        const a = try mgr.engineForOrigin(long_host);
        _ = try a.upsertDatabase("db", 7);
        const b = try mgr.engineForOrigin("https://b.com");
        try testing.expectEqual(null, try b.databaseVersion("db"));
    }

    {
        var mgr = try Manager.initPersistent(testing.allocator, abs_dir);
        defer mgr.deinit();
        const a = try mgr.engineForOrigin(long_host);
        try testing.expectEqual(7, (try a.databaseVersion("db")).?);
        const b = try mgr.engineForOrigin("https://b.com");
        try testing.expectEqual(null, try b.databaseVersion("db"));
    }
}
