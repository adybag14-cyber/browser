// Copyright (C) 2023-2026  Lightpanda (Selecy SAS)
//
// Francis Bouvier <francis@lightpanda.io>
// Pierre Tachoire <pierre@lightpanda.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
// for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const lp = @import("lightpanda");

const HostPaths = @import("../HostPaths.zig");

const Allocator = std.mem.Allocator;

fn storageResolveProfileDir(allocator: Allocator, override_path: ?[]const u8) ?[]const u8 {
    return HostPaths.resolveProfileDir(allocator, override_path);
}

fn storageResolveProfileSubdir(allocator: Allocator, profile_root: ?[]const u8, subdir: []const u8) ?[]u8 {
    return HostPaths.resolveProfileSubdir(allocator, profile_root, subdir);
}

pub const Storage = struct {
    mode: Mode = .hosted,
    files: std.ArrayListUnmanaged(FileEntry) = .empty,

    pub const Mode = enum {
        hosted,
        mock,
    };

    pub const FileEntry = struct {
        path: []u8,
        data: []u8,

        fn deinit(self: *FileEntry, allocator: Allocator) void {
            allocator.free(self.path);
            allocator.free(self.data);
            self.* = undefined;
        }
    };

    pub fn hosted() Storage {
        return .{ .mode = .hosted };
    }

    pub fn mock() Storage {
        return .{ .mode = .mock };
    }

    pub fn deinit(self: *Storage, allocator: Allocator) void {
        if (self.mode == .mock) {
            for (self.files.items) |*entry| {
                entry.deinit(allocator);
            }
        }
        self.files.deinit(allocator);
        self.* = undefined;
    }

    pub fn resolveProfileDir(self: *const Storage, allocator: Allocator, override_path: ?[]const u8) ?[]const u8 {
        return switch (self.mode) {
            .hosted => storageResolveProfileDir(allocator, override_path),
            .mock => {
                const path = override_path orelse "/mock/profile";
                return allocator.dupe(u8, path) catch null;
            },
        };
    }

    pub fn resolveProfileFile(self: *const Storage, allocator: Allocator, profile_root: ?[]const u8, name: []const u8) ?[]const u8 {
        _ = self;
        const root = profile_root orelse return null;
        return std.fs.path.join(allocator, &.{ root, name }) catch null;
    }

    pub fn resolveProfileSubdir(self: *const Storage, allocator: Allocator, profile_root: ?[]const u8, subdir: []const u8) ?[]const u8 {
        return switch (self.mode) {
            .hosted => storageResolveProfileSubdir(allocator, profile_root, subdir),
            .mock => {
                const root = profile_root orelse return null;
                return std.fs.path.join(allocator, &.{ root, subdir }) catch null;
            },
        };
    }

    pub fn writeFile(self: *Storage, allocator: Allocator, path: []const u8, data: []const u8) !void {
        switch (self.mode) {
            .hosted => {
                const file = if (std.fs.path.isAbsolute(path))
                    try std.Io.Dir.createFileAbsolute(lp.io, path, .{ .truncate = true })
                else
                    try std.Io.Dir.cwd().createFile(lp.io, path, .{ .truncate = true });
                defer file.close(lp.io);
                var writer = file.writerStreaming(lp.io, &.{});
                try writer.interface.writeAll(data);
            },
            .mock => {
                if (self.indexOf(path)) |index| {
                    var entry = &self.files.items[index];
                    const data_copy = try allocator.dupe(u8, data);
                    allocator.free(entry.data);
                    entry.data = data_copy;
                    return;
                }

                const path_copy = try allocator.dupe(u8, path);
                errdefer allocator.free(path_copy);
                const data_copy = try allocator.dupe(u8, data);
                errdefer allocator.free(data_copy);
                try self.files.append(allocator, .{
                    .path = path_copy,
                    .data = data_copy,
                });
            },
        }
    }

    pub fn readFile(self: *Storage, allocator: Allocator, path: []const u8) ![]u8 {
        switch (self.mode) {
            .hosted => {
                const file = if (std.fs.path.isAbsolute(path))
                    try std.Io.Dir.openFileAbsolute(lp.io, path, .{})
                else
                    try std.Io.Dir.cwd().openFile(lp.io, path, .{});
                defer file.close(lp.io);
                var read_buffer: [4096]u8 = undefined;
                var reader = file.reader(lp.io, &read_buffer);
                return try reader.interface.allocRemaining(allocator, .limited(1024 * 1024));
            },
            .mock => {
                const index = self.indexOf(path) orelse return error.FileNotFound;
                return allocator.dupe(u8, self.files.items[index].data);
            },
        }
    }

    pub fn deleteFile(self: *Storage, allocator: Allocator, path: []const u8) !void {
        switch (self.mode) {
            .hosted => {
                if (std.fs.path.isAbsolute(path)) {
                    try std.Io.Dir.deleteFileAbsolute(lp.io, path);
                } else {
                    try std.Io.Dir.cwd().deleteFile(lp.io, path);
                }
            },
            .mock => {
                const index = self.indexOf(path) orelse return error.FileNotFound;
                var entry = self.files.swapRemove(index);
                entry.deinit(allocator);
            },
        }
    }

    pub fn clear(self: *Storage, allocator: Allocator) void {
        if (self.mode == .mock) {
            while (self.files.items.len > 0) {
                var owned = self.files.pop();
                owned.deinit(allocator);
            }
        }
    }

    fn indexOf(self: *const Storage, path: []const u8) ?usize {
        for (self.files.items, 0..) |entry, index| {
            if (std.mem.eql(u8, entry.path, path)) {
                return index;
            }
        }
        return null;
    }
};

test "storage mock stores file contents in memory" {
    var storage = Storage.mock();
    defer storage.deinit(std.testing.allocator);

    const path = "tmp-mock-storage.txt";
    try storage.writeFile(std.testing.allocator, path, "hello");
    const data = try storage.readFile(std.testing.allocator, path);
    defer std.testing.allocator.free(data);

    try std.testing.expectEqualStrings("hello", data);
    try storage.deleteFile(std.testing.allocator, path);
    try std.testing.expectError(error.FileNotFound, storage.readFile(std.testing.allocator, path));
}
