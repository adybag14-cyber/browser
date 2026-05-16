// Copyright (C) 2023-2024  Lightpanda (Selecy SAS)
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
const compat = @import("../../compat.zig");
const builtin = @import("builtin");

pub fn processMessage(cmd: anytype) !void {
    const action = std.meta.stringToEnum(enum {
        enable,
        runIfWaitingForDebugger,
        evaluate,
        addBinding,
        callFunctionOn,
        releaseObject,
        getProperties,
    }, cmd.input.action) orelse return error.UnknownMethod;

    switch (action) {
        .runIfWaitingForDebugger => return cmd.sendResult(null, .{}),
        else => return sendInspector(cmd, action),
    }
}

fn sendInspector(cmd: anytype, action: anytype) !void {
    // save script in file at debug mode
    if (builtin.mode == .Debug) {
        try logInspector(cmd, action);
    }

    const bc = cmd.browser_context orelse return error.BrowserContextNotLoaded;
    const inspector_msg = try buildInspectorMessage(cmd);

    // The browser-context session id belongs to the outer CDP transport layer.
    // The nested V8 inspector payload must not include it.
    bc.callInspector(inspector_msg);
}

fn buildInspectorMessage(cmd: anytype) ![]const u8 {
    const header = try std.json.parseFromSliceLeaky(
        struct {
            id: ?i64 = null,
            method: []const u8,
        },
        cmd.arena,
        cmd.input.json,
        .{ .ignore_unknown_fields = true },
    );
    const id = header.id orelse return error.RequiredId;
    if (cmd.input.params) |params| {
        return std.fmt.allocPrint(
            cmd.arena,
            "{{\"id\":{d},\"method\":\"{s}\",\"params\":{s}}}",
            .{ id, header.method, params.raw },
        );
    }

    return std.fmt.allocPrint(
        cmd.arena,
        "{{\"id\":{d},\"method\":\"{s}\"}}",
        .{ id, header.method },
    );
}

fn logInspector(cmd: anytype, action: anytype) !void {
    const script = switch (action) {
        .evaluate => blk: {
            const params = (try cmd.params(struct {
                expression: []const u8,
                // contextId: ?u8 = null,
                // returnByValue: ?bool = null,
                // awaitPromise: ?bool = null,
                // userGesture: ?bool = null,
            })) orelse return error.InvalidParams;

            break :blk params.expression;
        },
        .callFunctionOn => blk: {
            const params = (try cmd.params(struct {
                functionDeclaration: []const u8,
                // objectId: ?[]const u8 = null,
                // executionContextId: ?u8 = null,
                // arguments: ?[]struct {
                //     value: ?[]const u8 = null,
                //     objectId: ?[]const u8 = null,
                // } = null,
                // returnByValue: ?bool = null,
                // awaitPromise: ?bool = null,
                // userGesture: ?bool = null,
            })) orelse return error.InvalidParams;

            break :blk params.functionDeclaration;
        },
        else => return,
    };
    const id = cmd.input.id orelse return error.RequiredId;
    const name = try std.fmt.allocPrint(cmd.arena, "id_{d}.js", .{id});

    var dir = try compat.fs.cwd().makeOpenPath(".zig-cache/tmp", .{});
    defer dir.close();

    const f = try dir.createFile(name, .{});
    defer f.close();
    try f.writeAll(script);
}

test "runtime inspector message strips top-level sessionId" {
    const allocator = std.testing.allocator;
    const raw = try std.fmt.allocPrint(
        allocator,
        "{{\"id\":7,\"method\":\"Runtime.evaluate\",\"params\":{{\"expression\":\"1+1\"}},\"sessionId\":\"SID-1\"}}",
        .{},
    );
    defer allocator.free(raw);

    const input = .{
        .id = @as(i64, 7),
        .method = "Runtime.evaluate",
        .params = @as(?struct { raw: []const u8 }, .{ .raw = "{\"expression\":\"1+1\"}" }),
        .json = raw,
    };
    const cmd = .{
        .arena = allocator,
        .input = input,
    };

    const inspector = try buildInspectorMessage(cmd);
    defer allocator.free(inspector);

    try std.testing.expectEqualStrings(
        "{\"id\":7,\"method\":\"Runtime.evaluate\",\"params\":{\"expression\":\"1+1\"}}",
        inspector,
    );
}
