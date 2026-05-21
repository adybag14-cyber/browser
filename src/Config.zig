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
const Allocator = std.mem.Allocator;

const log = @import("log.zig");
const dump = @import("browser/dump.zig");

pub const RunMode = enum {
    help,
    browse,
    fetch,
    serve,
    version,
    mcp,
};

pub const CDP_MAX_HTTP_REQUEST_SIZE = 4096;
pub const DEFAULT_VIEWPORT_WIDTH: u32 = 1920;
pub const DEFAULT_VIEWPORT_HEIGHT: u32 = 1080;
pub const DEFAULT_HTTP_TIMEOUT_MS: u31 = 5000;
pub const DEFAULT_INTERACTIVE_HTTP_TIMEOUT_MS: u31 = 30000;

// max message size
// +14 for max websocket payload overhead
// +140 for the max control packet that might be interleaved in a message
pub const CDP_MAX_MESSAGE_SIZE = 512 * 1024 + 14 + 140;

mode: Mode,
exec_name: []const u8,
http_headers: HttpHeaders,

const Config = @This();

pub fn init(allocator: Allocator, exec_name: []const u8, mode: Mode) !Config {
    var config = Config{
        .mode = mode,
        .exec_name = exec_name,
        .http_headers = undefined,
    };
    config.http_headers = try HttpHeaders.init(allocator, &config);
    return config;
}

pub fn deinit(self: *const Config, allocator: Allocator) void {
    self.http_headers.deinit(allocator);
}

pub fn tlsVerifyHost(self: *const Config) bool {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.tls_verify_host,
        else => unreachable,
    };
}

pub fn obeyRobots(self: *const Config) bool {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.obey_robots,
        else => unreachable,
    };
}

pub fn httpProxy(self: *const Config) ?[:0]const u8 {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.http_proxy,
        else => unreachable,
    };
}

pub fn proxyBearerToken(self: *const Config) ?[:0]const u8 {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.proxy_bearer_token,
        .help, .version => null,
    };
}

pub fn httpMaxConcurrent(self: *const Config) u8 {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.http_max_concurrent orelse 10,
        else => unreachable,
    };
}

pub fn httpMaxHostOpen(self: *const Config) u8 {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.http_max_host_open orelse 4,
        else => unreachable,
    };
}

pub fn httpConnectTimeout(self: *const Config) u31 {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.http_connect_timeout orelse 0,
        else => unreachable,
    };
}

pub fn httpTimeout(self: *const Config) u31 {
    return switch (self.mode) {
        .browse => |opts| opts.common.http_timeout orelse DEFAULT_INTERACTIVE_HTTP_TIMEOUT_MS,
        .serve => |opts| opts.common.http_timeout orelse if (opts.common.browser_mode == .headed)
            DEFAULT_INTERACTIVE_HTTP_TIMEOUT_MS
        else
            DEFAULT_HTTP_TIMEOUT_MS,
        inline .fetch, .mcp => |opts| opts.common.http_timeout orelse DEFAULT_HTTP_TIMEOUT_MS,
        else => unreachable,
    };
}

pub fn httpMaxRedirects(_: *const Config) u8 {
    return 10;
}

pub fn httpMaxResponseSize(self: *const Config) ?usize {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.http_max_response_size,
        else => unreachable,
    };
}

pub fn logLevel(self: *const Config) ?log.Level {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.log_level,
        else => unreachable,
    };
}

pub fn logFormat(self: *const Config) ?log.Format {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.log_format,
        else => unreachable,
    };
}

pub fn logFilterScopes(self: *const Config) ?[]const log.Scope {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.log_filter_scopes,
        else => unreachable,
    };
}

pub fn userAgentSuffix(self: *const Config) ?[]const u8 {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.user_agent_suffix,
        .help, .version => null,
    };
}

pub fn profileDir(self: *const Config) ?[]const u8 {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.profile_dir,
        .help, .version => null,
    };
}

pub fn browserMode(self: *const Config) BrowserMode {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.browser_mode,
        .help, .version => .headless,
    };
}

pub fn windowWidth(self: *const Config) u32 {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.window_width orelse DEFAULT_VIEWPORT_WIDTH,
        .help, .version => DEFAULT_VIEWPORT_WIDTH,
    };
}

pub fn windowHeight(self: *const Config) u32 {
    return switch (self.mode) {
        inline .serve, .fetch, .browse, .mcp => |opts| opts.common.window_height orelse DEFAULT_VIEWPORT_HEIGHT,
        .help, .version => DEFAULT_VIEWPORT_HEIGHT,
    };
}

pub fn maxConnections(self: *const Config) u16 {
    return switch (self.mode) {
        .serve => |opts| opts.cdp_max_connections,
        else => unreachable,
    };
}

pub fn maxPendingConnections(self: *const Config) u31 {
    return switch (self.mode) {
        .serve => |opts| opts.cdp_max_pending_connections,
        else => unreachable,
    };
}

pub const Mode = union(RunMode) {
    help: bool, // false when being printed because of an error
    browse: Browse,
    fetch: Fetch,
    serve: Serve,
    version: void,
    mcp: Mcp,
};

pub const Browse = struct {
    url: [:0]const u8,
    common: Common = .{ .browser_mode = .headed },
    screenshot_bmp_path: ?[:0]const u8 = null,
    screenshot_png_path: ?[:0]const u8 = null,
};

pub const Serve = struct {
    host: []const u8 = "127.0.0.1",
    port: u16 = 9222,
    timeout: u31 = 10,
    cdp_max_connections: u16 = 16,
    cdp_max_pending_connections: u16 = 128,
    common: Common = .{},
};

pub const Mcp = struct {
    common: Common = .{},
};

pub const DumpFormat = enum {
    html,
    markdown,
    wpt,
};

pub const Fetch = struct {
    url: [:0]const u8,
    dump_mode: ?DumpFormat = null,
    common: Common = .{},
    with_base: bool = false,
    with_frames: bool = false,
    strip: dump.Opts.Strip = .{},
};

pub const BrowserMode = enum {
    headless,
    headed,
};

pub const Common = struct {
    obey_robots: bool = false,
    proxy_bearer_token: ?[:0]const u8 = null,
    http_proxy: ?[:0]const u8 = null,
    http_max_concurrent: ?u8 = null,
    http_max_host_open: ?u8 = null,
    http_timeout: ?u31 = null,
    http_connect_timeout: ?u31 = null,
    http_max_response_size: ?usize = null,
    tls_verify_host: bool = true,
    log_level: ?log.Level = null,
    log_format: ?log.Format = null,
    log_filter_scopes: ?[]log.Scope = null,
    user_agent_suffix: ?[]const u8 = null,
    profile_dir: ?[:0]const u8 = null,
    browser_mode: BrowserMode = .headless,
    window_width: ?u32 = null,
    window_height: ?u32 = null,
};

/// Pre-formatted HTTP headers for reuse across Http and Client.
/// Must be initialized with an allocator that outlives all HTTP connections.
pub const HttpHeaders = struct {
    const user_agent_headless_base: [:0]const u8 = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/146.0.0.0 Safari/537.36";
    const user_agent_headed_base: [:0]const u8 = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36";

    user_agent: [:0]const u8, // User agent value (e.g. "Lightpanda/1.0")
    user_agent_header: [:0]const u8,

    proxy_bearer_header: ?[:0]const u8,

    pub fn init(allocator: Allocator, config: *const Config) !HttpHeaders {
        const user_agent_base = if (config.browserMode() == .headed) user_agent_headed_base else user_agent_headless_base;
        const user_agent: [:0]const u8 = if (config.userAgentSuffix()) |suffix|
            try std.fmt.allocPrintSentinel(allocator, "{s} {s}", .{ user_agent_base, suffix }, 0)
        else
            user_agent_base;
        errdefer if (config.userAgentSuffix() != null) allocator.free(user_agent);

        const user_agent_header = try std.fmt.allocPrintSentinel(allocator, "User-Agent: {s}", .{user_agent}, 0);
        errdefer allocator.free(user_agent_header);

        const proxy_bearer_header: ?[:0]const u8 = if (config.proxyBearerToken()) |token|
            try std.fmt.allocPrintSentinel(allocator, "Proxy-Authorization: Bearer {s}", .{token}, 0)
        else
            null;

        return .{
            .user_agent = user_agent,
            .user_agent_header = user_agent_header,
            .proxy_bearer_header = proxy_bearer_header,
        };
    }

    pub fn deinit(self: *const HttpHeaders, allocator: Allocator) void {
        if (self.proxy_bearer_header) |hdr| {
            allocator.free(hdr);
        }
        allocator.free(self.user_agent_header);
        if (self.user_agent.ptr != user_agent_headless_base.ptr and self.user_agent.ptr != user_agent_headed_base.ptr) {
            allocator.free(self.user_agent);
        }
    }
};

pub fn printHelp(self: *const Config, err: ?anyerror) void {
    if (err) |e| {
        std.debug.print("error: {s}\n", .{@errorName(e)});
    }

    const common_options =
        \\
        \\--obey_robots
        \\                Fetches and obeys the robots.txt (if available) of the web pages
        \\                we make requests towards.
        \\                Defaults to false.
        \\
        \\--http_proxy    The HTTP proxy to use for all HTTP requests.
        \\                A username:password can be included for basic authentication.
        \\                Defaults to none.
        \\
        \\--proxy_bearer_token
        \\                The <token> to send for bearer authentication with the proxy
        \\                Proxy-Authorization: Bearer <token>
        \\
        \\--http_max_concurrent
        \\                The maximum number of concurrent HTTP requests.
        \\                Defaults to 10.
        \\
        \\--http_max_host_open
        \\                The maximum number of open connection to a given host:port.
        \\                Defaults to 4.
        \\
        \\--http_connect_timeout
        \\                The time, in milliseconds, for establishing an HTTP connection
        \\                before timing out. 0 means it never times out.
        \\                Defaults to 0.
        \\
        \\--http_timeout
        \\                The maximum time, in milliseconds, the transfer is allowed
        \\                to complete. 0 means it never times out.
        \\                Defaults to 30000 for browse and headed serve.
        \\                Defaults to 5000 for headless serve, fetch, and mcp.
        \\
        \\--http_max_response_size
        \\                Limits the acceptable response size for any request
        \\                (e.g. XHR, fetch, script loading, ...).
        \\                Defaults to no limit.
        \\
        \\--log_level     The log level: debug, info, warn, error or fatal.
        \\                Defaults to
    ++ (if (builtin.mode == .Debug) " info." else "warn.") ++
        \\
        \\
        \\--log_format    The log format: pretty or logfmt.
        \\                Defaults to
    ++ (if (builtin.mode == .Debug) " pretty." else " logfmt.") ++
        \\
        \\
        \\--log_filter_scopes
        \\                Filter out too verbose logs per scope:
        \\                http, unknown_prop, event, ...
        \\
        \\--user_agent_suffix
        \\                Suffix to append to the Lightpanda/X.Y User-Agent
        \\
        \\--profile_dir   Explicit browser profile root for cookies, storage,
        \\                downloads, telemetry IDs, and other persisted state.
        \\                Defaults to the platform app-data directory when
        \\                available.
        \\
        \\--browser_mode  Browser mode: headless or headed.
        \\                Defaults to headless for serve, fetch, and mcp.
        \\                Defaults to headed for browse.
        \\
        \\--headed        Shortcut for '--browser_mode headed'
        \\
        \\--headless      Shortcut for '--browser_mode headless'
        \\
        \\--window_width  Window/viewport width in CSS pixels.
        \\                Defaults to 1920.
        \\
        \\--window_height Window/viewport height in CSS pixels.
        \\                Defaults to 1080.
        \\
    ;

    //                                                                     MAX_HELP_LEN|
    const usage =
        \\usage: {s} command [options] [URL]
        \\
        \\Command can be either 'browse', 'fetch', 'serve', 'mcp' or 'help'
        \\
        \\browse command
        \\Opens the specified URL in a native browser window.
        \\Example: {s} browse https://lightpanda.io/
        \\
        \\Options:
        \\--screenshot_bmp
        \\                Save the first rendered headed browse frame as a BMP file.
        \\                Argument must be the output path.
        \\
        \\--screenshot_png
        \\                Save the first rendered headed browse frame as a PNG file.
        \\                Argument must be the output path.
        \\
    ++ common_options ++
        \\
        \\fetch command
        \\Fetches the specified URL
        \\Example: {s} fetch --dump html https://lightpanda.io/
        \\
        \\Options:
        \\--dump          Dumps document to stdout.
        \\                Optional formats: html, markdown, wpt.
        \\                Defaults to html.
        \\
        \\--with-base     Prepends base URL to links in markdown.
        \\                Ignored unless --dump markdown.
        \\
        \\--with-frames   Includes HTML for frames and iframes.
        \\                These subtrees are excluded by default.
        \\
        \\--strip         Strips selected fields in the dump. Repeatable.
        \\                Choices: script, style, noscript, comment, cdata, iframe, event, hidden, meta.
        \\
    ++ common_options ++
        \\
        \\serve command
        \\Runs a server exposing the HTTP/WebSocket Chrome DevTools Protocol.
        \\Example: {s} serve
        \\
        \\Options:
        \\--host          The host to listen on.
        \\                Defaults to 127.0.0.1.
        \\
        \\--port          The port to listen on.
        \\                Defaults to 9222.
        \\
        \\--timeout       The maximum number of seconds to wait for the browser instance
        \\                to shut down after the last client disconnects.
        \\                0 means it never times out.
        \\                Defaults to 10.
        \\
        \\--cdp_max_connections
        \\                The maximum number of concurrent HTTP clients.
        \\                Defaults to 16.
        \\
        \\--cdp_max_pending_connections
        \\                The maximum number of pending HTTP clients.
        \\                Defaults to 128.
        \\
    ++ common_options ++
        \\
        \\mcp command
        \\Runs an MCP server over stdio.
        \\Example: {s} mcp
        \\
        \\Options:
    ++ common_options ++
        \\
        \\help command
        \\Print this help and exits.
    ;

    std.debug.print(usage, .{ self.exec_name, self.exec_name, self.exec_name, self.exec_name, self.exec_name, self.exec_name });
}

pub fn parse(allocator: Allocator, process: std.process.ArgIterator) ParseError!Config {
    var args = process;

    const exec_name = args.next() orelse @panic("missing process name");
    const mode = blk: {
        const m = try inferMode(allocator, &args);
        switch (m) {
            .help => {
                _ = args.next();
                break :blk Mode{ .help = true };
            },
            .version => {
                _ = args.next();
                break :blk .version;
            },
            else => |mode| {
                _ = args.next();
                break :blk try parseMode(allocator, mode, &args);
            },
        }
    };

    return Config.init(allocator, exec_name, mode);
}

pub const ParseError = error{InvalidArgument};

pub fn inferMode(allocator: Allocator, process: *std.process.ArgIterator) ParseError!RunMode {
    var args = process;
    _ = args.next();

    var tokens: std.ArrayList([]const u8) = .empty;
    defer tokens.deinit(allocator);

    while (args.next()) |token| {
        try tokens.append(allocator, token);
    }

    return inferModeSlice(tokens.items);
}

fn inferModeSlice(tokens: []const []const u8) ParseError!RunMode {
    var shared_opts = Config.Common{};
    var browse_hint = false;

    var index: usize = 0;
    while (index < tokens.len) {
        const token = tokens[index];
        if (inferBrowseOption(token)) {
            return .browse;
        }

        if (std.mem.eql(u8, token, "--browser_mode")) {
            browse_hint = true;
            if (index + 1 < tokens.len) {
                shared_opts.browser_mode = std.meta.stringToEnum(BrowserMode, tokens[index + 1]) orelse shared_opts.browser_mode;
                index += 2;
            } else {
                index += 1;
            }
            continue;
        }

        if (std.mem.eql(u8, token, "--headed")) {
            browse_hint = true;
            shared_opts.browser_mode = .headed;
            index += 1;
            continue;
        }
        if (std.mem.eql(u8, token, "--headless")) {
            browse_hint = true;
            shared_opts.browser_mode = .headless;
            index += 1;
            continue;
        }

        if (std.mem.eql(u8, token, "--window_width") or std.mem.eql(u8, token, "--window_height")) {
            browse_hint = true;
            if (index + 1 < tokens.len) {
                index += 2;
            } else {
                index += 1;
            }
            continue;
        }

        if (inferModeOption(token)) {
            if (index + 1 < tokens.len) {
                index += 2;
            } else {
                index += 1;
            }
            continue;
        }

        if (std.mem.eql(u8, token, "browse")) {
            return .browse;
        }
        if (std.mem.eql(u8, token, "fetch")) {
            return .fetch;
        }
        if (std.mem.eql(u8, token, "serve")) {
            return .serve;
        }
        if (std.mem.eql(u8, token, "mcp")) {
            return .mcp;
        }
        if (std.mem.eql(u8, token, "help")) {
            return .help;
        }
        if (std.mem.eql(u8, token, "--help") or std.mem.eql(u8, token, "-h")) {
            return .help;
        }
        if (std.mem.eql(u8, token, "--version")) {
            return .version;
        }

        if (inferSharedFlagOption(token)) {
            index += 1;
            continue;
        }

        if (inferLocalBrowseTarget(token)) {
            return .browse;
        }

        return if (std.mem.indexOfAny(u8, token, ":/") == null)
            .serve
        else if (browse_hint or shared_opts.browser_mode == .headed)
            .browse
        else
            .fetch;
    }

    return .help;
}

fn inferBrowseOption(opt: []const u8) bool {
    if (std.mem.eql(u8, opt, "--screenshot_bmp")) {
        return true;
    }
    if (std.mem.eql(u8, opt, "--screenshot_png")) {
        return true;
    }
    return false;
}

fn inferModeOption(opt: []const u8) bool {
    if (std.mem.eql(u8, opt, "--http_proxy")) {
        return true;
    }
    if (std.mem.eql(u8, opt, "--proxy_bearer_token")) {
        return true;
    }
    if (std.mem.eql(u8, opt, "--http_max_concurrent")) {
        return true;
    }
    if (std.mem.eql(u8, opt, "--http_max_host_open")) {
        return true;
    }
    if (std.mem.eql(u8, opt, "--http_timeout")) {
        return true;
    }
    if (std.mem.eql(u8, opt, "--http_connect_timeout")) {
        return true;
    }
    if (std.mem.eql(u8, opt, "--http_max_response_size")) {
        return true;
    }
    if (std.mem.eql(u8, opt, "--log_level")) {
        return true;
    }
    if (std.mem.eql(u8, opt, "--log_format")) {
        return true;
    }
    if (std.mem.eql(u8, opt, "--log_filter_scopes")) {
        return true;
    }
    if (std.mem.eql(u8, opt, "--user_agent_suffix")) {
        return true;
    }
    if (std.mem.eql(u8, opt, "--profile_dir")) {
        return true;
    }
    return false;
}

fn inferSharedFlagOption(opt: []const u8) bool {
    if (std.mem.eql(u8, opt, "--obey_robots")) {
        return true;
    }
    return false;
}

fn inferLocalBrowseTarget(token: []const u8) bool {
    if (std.ascii.startsWithIgnoreCase(token, "file://")) {
        return true;
    }
    if (std.mem.indexOf(u8, token, "://") != null) {
        return false;
    }
    if (token.len >= 6 and std.ascii.eqlIgnoreCase(token[token.len - 6 ..], ".xhtml")) {
        return true;
    }
    if (token.len >= 5 and std.ascii.eqlIgnoreCase(token[token.len - 5 ..], ".html")) {
        return true;
    }
    if (token.len >= 4 and std.ascii.eqlIgnoreCase(token[token.len - 4 ..], ".htm")) {
        return true;
    }
    return false;
}

pub fn parseMode(allocator: Allocator, mode: RunMode, process: *std.process.ArgIterator) ParseError!Mode {
    return switch (mode) {
        .browse => .{ .browse = try parseBrowse(allocator, process) },
        .fetch => .{ .fetch = try parseFetch(allocator, process) },
        .serve => .{ .serve = try parseServe(allocator, process) },
        .mcp => .{ .mcp = try parseMcp(allocator, process) },
        else => unreachable,
    };
}

pub fn parseBrowse(allocator: Allocator, process: *std.process.ArgIterator) ParseError!Browse {
    var args = process;
    var common: Common = .{ .browser_mode = .headed };
    var screenshot_bmp_path: ?[:0]const u8 = null;
    var screenshot_png_path: ?[:0]const u8 = null;

    const url = while (args.next()) |opt| {
        if (std.mem.eql(u8, "--screenshot_bmp", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--screenshot_bmp" });
                return error.InvalidArgument;
            };

            screenshot_bmp_path = try allocator.dupeZ(u8, str);
            continue;
        }

        if (std.mem.eql(u8, "--screenshot_png", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--screenshot_png" });
                return error.InvalidArgument;
            };

            screenshot_png_path = try allocator.dupeZ(u8, str);
            continue;
        }

        if (try parseCommon(allocator, opt, &common, &args)) {
            continue;
        }

        break opt;
    } else {
        log.fatal(.app, "missing URL", .{});
        return error.InvalidArgument;
    };

    return .{
        .url = try allocator.dupeZ(u8, url),
        .common = common,
        .screenshot_bmp_path = screenshot_bmp_path,
        .screenshot_png_path = screenshot_png_path,
    };
}

pub fn parseFetch(allocator: Allocator, process: *std.process.ArgIterator) ParseError!Fetch {
    var args = process;
    var common: Common = .{};

    var with_base = false;
    var with_frames = false;
    var dump_mode: ?DumpFormat = null;
    var strip: dump.Opts.Strip = .{};

    const url = while (args.next()) |opt| {
        if (std.mem.eql(u8, "--dump", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--dump" });
                return error.InvalidArgument;
            };
            dump_mode = std.meta.stringToEnum(DumpFormat, str) orelse {
                log.fatal(.app, "invalid option choice", .{ .arg = "--dump", .value = str });
                return error.InvalidArgument;
            };
            continue;
        }

        if (std.mem.eql(u8, "--with-base", opt)) {
            with_base = true;
            continue;
        }

        if (std.mem.eql(u8, "--with-frames", opt)) {
            with_frames = true;
            continue;
        }

        if (std.mem.eql(u8, "--strip", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--strip" });
                return error.InvalidArgument;
            };
            if (std.mem.eql(u8, "script", str)) {
                strip.script = true;
            } else if (std.mem.eql(u8, "style", str)) {
                strip.style = true;
            } else if (std.mem.eql(u8, "noscript", str)) {
                strip.noscript = true;
            } else if (std.mem.eql(u8, "comment", str)) {
                strip.comment = true;
            } else if (std.mem.eql(u8, "cdata", str)) {
                strip.cdata = true;
            } else if (std.mem.eql(u8, "iframe", str)) {
                strip.iframe = true;
            } else if (std.mem.eql(u8, "event", str)) {
                strip.event = true;
            } else if (std.mem.eql(u8, "hidden", str)) {
                strip.hidden = true;
            } else if (std.mem.eql(u8, "meta", str)) {
                strip.meta = true;
            } else {
                log.fatal(.app, "invalid option choice", .{ .arg = "--strip", .value = str });
                return error.InvalidArgument;
            }
            continue;
        }

        if (try parseCommon(allocator, opt, &common, &args)) {
            continue;
        }

        break opt;
    } else {
        log.fatal(.app, "missing URL", .{});
        return error.InvalidArgument;
    };

    return .{
        .url = try allocator.dupeZ(u8, url),
        .dump_mode = dump_mode,
        .common = common,
        .with_base = with_base,
        .with_frames = with_frames,
        .strip = strip,
    };
}

pub fn parseServe(allocator: Allocator, process: *std.process.ArgIterator) ParseError!Serve {
    var args = process;
    var serve = Serve{};

    while (args.next()) |opt| {
        if (std.mem.eql(u8, "--host", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--host" });
                return error.InvalidArgument;
            };
            serve.host = str;
            continue;
        }

        if (std.mem.eql(u8, "--port", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--port" });
                return error.InvalidArgument;
            };

            serve.port = std.fmt.parseInt(u16, str, 10) catch |err| {
                log.fatal(.app, "invalid argument value", .{ .arg = "--port", .err = err });
                return error.InvalidArgument;
            };
            continue;
        }

        if (std.mem.eql(u8, "--timeout", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--timeout" });
                return error.InvalidArgument;
            };

            serve.timeout = std.fmt.parseInt(u31, str, 10) catch |err| {
                log.fatal(.app, "invalid argument value", .{ .arg = "--timeout", .err = err });
                return error.InvalidArgument;
            };
            continue;
        }

        if (std.mem.eql(u8, "--cdp_max_connections", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--cdp_max_connections" });
                return error.InvalidArgument;
            };

            serve.cdp_max_connections = std.fmt.parseInt(u16, str, 10) catch |err| {
                log.fatal(.app, "invalid argument value", .{ .arg = "--cdp_max_connections", .err = err });
                return error.InvalidArgument;
            };
            continue;
        }

        if (std.mem.eql(u8, "--cdp_max_pending_connections", opt)) {
            const str = args.next() orelse {
                log.fatal(.app, "missing argument value", .{ .arg = "--cdp_max_pending_connections" });
                return error.InvalidArgument;
            };

            serve.cdp_max_pending_connections = std.fmt.parseInt(u16, str, 10) catch |err| {
                log.fatal(.app, "invalid argument value", .{ .arg = "--cdp_max_pending_connections", .err = err });
                return error.InvalidArgument;
            };
            continue;
        }

        if (try parseCommon(allocator, opt, &serve.common, &args)) {
            continue;
        }

        log.fatal(.app, "unknown argument", .{ .arg = opt });
        return error.InvalidArgument;
    }

    return serve;
}

pub fn parseMcp(allocator: Allocator, process: *std.process.ArgIterator) ParseError!Mcp {
    var args = process;
    var mcp = Mcp{};

    while (args.next()) |opt| {
        if (try parseCommon(allocator, opt, &mcp.common, &args)) {
            continue;
        }

        log.fatal(.app, "unknown argument", .{ .arg = opt });
        return error.InvalidArgument;
    }

    return mcp;
}

pub fn parseCommon(allocator: Allocator, opt: []const u8, common: *Common, args: *std.process.ArgIterator) ParseError!bool {
    if (std.mem.eql(u8, "--obey_robots", opt)) {
        common.obey_robots = true;
        return true;
    }

    if (std.mem.eql(u8, "--http_proxy", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--http_proxy" });
            return error.InvalidArgument;
        };

        common.http_proxy = try allocator.dupeZ(u8, str);
        return true;
    }

    if (std.mem.eql(u8, "--proxy_bearer_token", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--proxy_bearer_token" });
            return error.InvalidArgument;
        };

        common.proxy_bearer_token = try allocator.dupeZ(u8, str);
        return true;
    }

    if (std.mem.eql(u8, "--http_max_concurrent", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--http_max_concurrent" });
            return error.InvalidArgument;
        };

        common.http_max_concurrent = std.fmt.parseInt(u8, str, 10) catch |err| {
            log.fatal(.app, "invalid argument value", .{ .arg = "--http_max_concurrent", .err = err });
            return error.InvalidArgument;
        };
        if (common.http_max_concurrent.? == 0) {
            log.fatal(.app, "invalid argument value", .{ .arg = "--http_max_concurrent", .value = str });
            return error.InvalidArgument;
        }
        return true;
    }

    if (std.mem.eql(u8, "--http_max_host_open", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--http_max_host_open" });
            return error.InvalidArgument;
        };

        common.http_max_host_open = std.fmt.parseInt(u8, str, 10) catch |err| {
            log.fatal(.app, "invalid argument value", .{ .arg = "--http_max_host_open", .err = err });
            return error.InvalidArgument;
        };
        if (common.http_max_host_open.? == 0) {
            log.fatal(.app, "invalid argument value", .{ .arg = "--http_max_host_open", .value = str });
            return error.InvalidArgument;
        }
        return true;
    }

    if (std.mem.eql(u8, "--http_connect_timeout", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--http_connect_timeout" });
            return error.InvalidArgument;
        };

        common.http_connect_timeout = std.fmt.parseInt(u31, str, 10) catch |err| {
            log.fatal(.app, "invalid argument value", .{ .arg = "--http_connect_timeout", .err = err });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--http_timeout", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--http_timeout" });
            return error.InvalidArgument;
        };

        common.http_timeout = std.fmt.parseInt(u31, str, 10) catch |err| {
            log.fatal(.app, "invalid argument value", .{ .arg = "--http_timeout", .err = err });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--http_max_response_size", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--http_max_response_size" });
            return error.InvalidArgument;
        };

        common.http_max_response_size = std.fmt.parseInt(usize, str, 10) catch |err| {
            log.fatal(.app, "invalid argument value", .{ .arg = "--http_max_response_size", .err = err });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--log_level", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--log_level" });
            return error.InvalidArgument;
        };

        common.log_level = std.meta.stringToEnum(log.Level, str) orelse blk: {
            if (std.mem.eql(u8, str, "error")) {
                break :blk .err;
            }
            log.fatal(.app, "invalid option choice", .{ .arg = "--log_level", .value = str });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--log_format", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--log_format" });
            return error.InvalidArgument;
        };

        common.log_format = std.meta.stringToEnum(log.Format, str) orelse {
            log.fatal(.app, "invalid option choice", .{ .arg = "--log_format", .value = str });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--log_filter_scopes", opt)) {
        if (builtin.mode != .Debug) {
            log.fatal(.app, "experimental", .{ .help = "log scope filtering is only available in debug builds" });
            return false;
        }

        const str = args.next() orelse {
            // disables the default filters
            common.log_filter_scopes = &.{};
            return true;
        };

        var arr: std.ArrayList(log.Scope) = .empty;

        var it = std.mem.splitScalar(u8, str, ',');
        while (it.next()) |part| {
            try arr.append(allocator, std.meta.stringToEnum(log.Scope, part) orelse {
                log.fatal(.app, "invalid option choice", .{ .arg = "--log_filter_scopes", .value = part });
                return false;
            });
        }
        common.log_filter_scopes = arr.items;
        return true;
    }

    if (std.mem.eql(u8, "--user_agent_suffix", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--user_agent_suffix" });
            return error.InvalidArgument;
        };
        for (str) |c| {
            if (!std.ascii.isPrint(c)) {
                log.fatal(.app, "not printable character", .{ .arg = "--user_agent_suffix" });
                return error.InvalidArgument;
            }
        }
        common.user_agent_suffix = try allocator.dupe(u8, str);
        return true;
    }

    if (std.mem.eql(u8, "--profile_dir", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--profile_dir" });
            return error.InvalidArgument;
        };
        common.profile_dir = try allocator.dupeZ(u8, str);
        return true;
    }

    if (std.mem.eql(u8, "--browser_mode", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--browser_mode" });
            return error.InvalidArgument;
        };

        common.browser_mode = std.meta.stringToEnum(BrowserMode, str) orelse {
            log.fatal(.app, "invalid option choice", .{ .arg = "--browser_mode", .value = str });
            return error.InvalidArgument;
        };
        return true;
    }

    if (std.mem.eql(u8, "--headed", opt)) {
        common.browser_mode = .headed;
        return true;
    }

    if (std.mem.eql(u8, "--headless", opt)) {
        common.browser_mode = .headless;
        return true;
    }

    if (std.mem.eql(u8, "--window_width", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--window_width" });
            return error.InvalidArgument;
        };

        common.window_width = std.fmt.parseInt(u32, str, 10) catch |err| {
            log.fatal(.app, "invalid argument value", .{ .arg = "--window_width", .err = err });
            return error.InvalidArgument;
        };
        if (common.window_width.? == 0) {
            log.fatal(.app, "invalid argument value", .{ .arg = "--window_width", .value = str });
            return error.InvalidArgument;
        }
        return true;
    }

    if (std.mem.eql(u8, "--window_height", opt)) {
        const str = args.next() orelse {
            log.fatal(.app, "missing argument value", .{ .arg = "--window_height" });
            return error.InvalidArgument;
        };

        common.window_height = std.fmt.parseInt(u32, str, 10) catch |err| {
            log.fatal(.app, "invalid argument value", .{ .arg = "--window_height", .err = err });
            return error.InvalidArgument;
        };
        if (common.window_height.? == 0) {
            log.fatal(.app, "invalid argument value", .{ .arg = "--window_height", .value = str });
            return error.InvalidArgument;
        }
        return true;
    }

    return false;
}

test "browse defaults to interactive http timeout" {
    var config = try Config.init(std.testing.allocator, "test", .{
        .browse = .{ .url = "https://example.com/" },
    });
    defer config.deinit(std.testing.allocator);

    try std.testing.expectEqual(DEFAULT_INTERACTIVE_HTTP_TIMEOUT_MS, config.httpTimeout());
}

test "headed serve defaults to interactive http timeout" {
    var config = try Config.init(std.testing.allocator, "test", .{
        .serve = .{ .common = .{ .browser_mode = .headed } },
    });
    defer config.deinit(std.testing.allocator);

    try std.testing.expectEqual(DEFAULT_INTERACTIVE_HTTP_TIMEOUT_MS, config.httpTimeout());
}

test "headless serve keeps shorter default http timeout" {
    var config = try Config.init(std.testing.allocator, "test", .{
        .serve = .{},
    });
    defer config.deinit(std.testing.allocator);

    try std.testing.expectEqual(DEFAULT_HTTP_TIMEOUT_MS, config.httpTimeout());
}

test "fetch keeps shorter default http timeout" {
    var config = try Config.init(std.testing.allocator, "test", .{
        .fetch = .{ .url = "https://example.com/" },
    });
    defer config.deinit(std.testing.allocator);

    try std.testing.expectEqual(DEFAULT_HTTP_TIMEOUT_MS, config.httpTimeout());
}

test "mcp keeps shorter default http timeout" {
    var config = try Config.init(std.testing.allocator, "test", .{
        .mcp = .{},
    });
    defer config.deinit(std.testing.allocator);

    try std.testing.expectEqual(DEFAULT_HTTP_TIMEOUT_MS, config.httpTimeout());
}

test "explicit http timeout overrides interactive defaults" {
    var config = try Config.init(std.testing.allocator, "test", .{
        .browse = .{
            .url = "https://example.com/",
            .common = .{
                .browser_mode = .headed,
                .http_timeout = 1234,
            },
        },
    });
    defer config.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(u31, 1234), config.httpTimeout());
}

test "infer mode keeps headed browse after obey robots flag" {
    const mode = try inferModeSlice(&.{ "--obey_robots", "--headed", "https://example.com/" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats headed shortcut before url as browse" {
    const mode = try inferModeSlice(&.{ "--headed", "https://example.com/" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats headless shortcut before url as browse" {
    const mode = try inferModeSlice(&.{ "--headless", "https://example.com/" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats browser mode headed before url as browse" {
    const mode = try inferModeSlice(&.{ "--browser_mode", "headed", "https://example.com/" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats browser mode headless before url as browse" {
    const mode = try inferModeSlice(&.{ "--browser_mode", "headless", "https://example.com/" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats window width before url as browse" {
    const mode = try inferModeSlice(&.{ "--window_width", "1280", "https://example.com/" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats window height before url as browse" {
    const mode = try inferModeSlice(&.{ "--window_height", "720", "https://example.com/" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats bare html filename as browse" {
    const mode = try inferModeSlice(&.{ "attached-page.html" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats relative windows html path as browse" {
    const mode = try inferModeSlice(&.{ "agent_files\\attached-page.html" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats absolute windows html path as browse" {
    const mode = try inferModeSlice(&.{ "C:\\fixtures\\attached-page.html" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats bare xhtml filename as browse" {
    const mode = try inferModeSlice(&.{ "attached-page.xhtml" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats relative windows xhtml path as browse" {
    const mode = try inferModeSlice(&.{ "agent_files\\attached-page.xhtml" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats file url as browse" {
    const mode = try inferModeSlice(&.{ "file:///tmp/attached-page.html" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode keeps browse for html target after shared flag" {
    const mode = try inferModeSlice(&.{ "--obey_robots", "agent_files\\attached-page.html" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode keeps browse for xhtml target after shared flag" {
    const mode = try inferModeSlice(&.{ "--obey_robots", "agent_files\\attached-page.xhtml" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode keeps browse for file url after shared flag" {
    const mode = try inferModeSlice(&.{
        "--profile_dir",
        "/tmp/lightpanda-profile",
        "file:///tmp/attached-page.xhtml",
    });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode keeps fetch fallback after obey robots flag" {
    const mode = try inferModeSlice(&.{ "--obey_robots", "https://example.com/" });

    try std.testing.expectEqual(RunMode.fetch, mode);
}

test "infer mode keeps fetch for remote html url without browse hint" {
    const mode = try inferModeSlice(&.{ "https://example.com/attached-page.html" });

    try std.testing.expectEqual(RunMode.fetch, mode);
}

test "infer mode keeps fetch for remote htm url without browse hint" {
    const mode = try inferModeSlice(&.{ "https://example.com/attached-page.htm" });

    try std.testing.expectEqual(RunMode.fetch, mode);
}

test "infer mode keeps browse for remote html url after headed shortcut" {
    const mode = try inferModeSlice(&.{ "--headed", "https://example.com/attached-page.html" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode treats screenshot png option as browse" {
    const mode = try inferModeSlice(&.{ "--screenshot_png", "capture.png", "https://example.com/" });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode keeps browse after shared options before screenshot bmp" {
    const mode = try inferModeSlice(&.{
        "--profile_dir",
        "/tmp/lightpanda-profile",
        "--screenshot_bmp",
        "capture.bmp",
        "https://example.com/",
    });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode keeps browse after headed shortcut and shared option before url" {
    const mode = try inferModeSlice(&.{
        "--headed",
        "--http_timeout",
        "30000",
        "https://example.com/",
    });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode keeps browse after browser mode headed and shared option before url" {
    const mode = try inferModeSlice(&.{
        "--browser_mode",
        "headed",
        "--profile_dir",
        "/tmp/lightpanda-profile",
        "https://example.com/",
    });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode keeps browse after shared option before window width and url" {
    const mode = try inferModeSlice(&.{
        "--profile_dir",
        "/tmp/lightpanda-profile",
        "--window_width",
        "1280",
        "https://example.com/",
    });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode keeps browse after window height and shared option before url" {
    const mode = try inferModeSlice(&.{
        "--window_height",
        "720",
        "--http_timeout",
        "30000",
        "https://example.com/",
    });

    try std.testing.expectEqual(RunMode.browse, mode);
}

test "infer mode keeps browse after headless shortcut and window width before url" {
    const mode = try inferModeSlice(&.{
        "--headless",
        "--window_width",
        "1280",
        "https://example.com/",
    });

    try std.testing.expectEqual(RunMode.browse, mode);
}