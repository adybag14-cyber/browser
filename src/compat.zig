pub fn repeatComptime(comptime pattern: []const u8, comptime count: usize) [pattern.len * count]u8 {
    @setEvalBranchQuota(@max(1_000_000, 1024 + count * 64));
    var out: [pattern.len * count]u8 = undefined;
    for (0..count) |i| {
        @memcpy(out[i * pattern.len ..][0..pattern.len], pattern);
    }
    return out;
}

const std = @import("std");

pub fn MemoryPool(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        pool: std.heap.MemoryPool(T) = .empty,

        pub fn init(allocator: std.mem.Allocator) @This() {
            return .{ .allocator = allocator };
        }

        pub fn deinit(self: *@This()) void {
            self.pool.deinit(self.allocator);
        }

        pub fn reset(self: *@This(), mode: std.heap.ArenaAllocator.ResetMode) bool {
            return self.pool.reset(self.allocator, mode);
        }

        pub fn create(self: *@This()) !*T {
            return self.pool.create(self.allocator);
        }

        pub fn destroy(self: *@This(), ptr: *T) void {
            self.pool.destroy(ptr);
        }
    };
}

/// Minimal blocking mutex shim for Zig 0.17's std.Thread.Mutex removal.
///
/// Keep this tiny: once Zig's IO-aware mutex story settles for non-async app
/// code, callers can move to the std type behind this API without touching
/// browser/runtime logic.
pub const Mutex = struct {
    state: std.atomic.Mutex = .unlocked,

    pub fn lock(self: *Mutex) void {
        while (!self.state.tryLock()) {
            std.atomic.spinLoopHint();
        }
    }

    pub fn unlock(self: *Mutex) void {
        self.state.unlock();
    }
};

pub const Condition = struct {
    epoch: std.atomic.Value(u64) = .init(0),

    pub fn wait(self: *Condition, mutex: *Mutex) void {
        const observed = self.epoch.load(.acquire);
        mutex.unlock();
        while (self.epoch.load(.acquire) == observed) {
            std.atomic.spinLoopHint();
        }
        mutex.lock();
    }

    pub fn signal(self: *Condition) void {
        _ = self.epoch.fetchAdd(1, .release);
    }

    pub fn broadcast(self: *Condition) void {
        self.signal();
    }
};

pub const WaitGroup = struct {
    mutex: Mutex = .{},
    cond: Condition = .{},
    count: usize = 0,

    pub fn startMany(self: *WaitGroup, count: usize) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.count += count;
    }

    pub fn start(self: *WaitGroup) void {
        self.startMany(1);
    }

    pub fn finish(self: *WaitGroup) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.count -= 1;
        if (self.count == 0) {
            self.cond.signal();
        }
    }

    pub fn wait(self: *WaitGroup) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        while (self.count != 0) {
            self.cond.wait(&self.mutex);
        }
    }
};

pub fn Once(comptime f: fn () void) type {
    return struct {
        done: std.atomic.Value(bool) = .init(false),
        mutex: Mutex = .{},

        pub fn call(self: *@This()) void {
            if (self.done.load(.acquire)) {
                return;
            }

            self.mutex.lock();
            defer self.mutex.unlock();

            if (!self.done.load(.acquire)) {
                f();
                self.done.store(true, .release);
            }
        }
    };
}

pub fn io() std.Io {
    return std.Io.Threaded.global_single_threaded.io();
}

pub fn sleepNanos(nanos: u64) void {
    const duration = std.Io.Duration.fromNanoseconds(@intCast(nanos));
    std.Io.sleep(io(), duration, .boot) catch {};
}

pub fn sleepMillis(millis: u64) void {
    sleepNanos(millis * std.time.ns_per_ms);
}

pub fn microTimestamp() i64 {
    return std.Io.Clock.real.now(io()).toMicroseconds();
}

pub fn monotonicNanoseconds() i96 {
    return std.Io.Clock.boot.now(io()).toNanoseconds();
}

pub fn intToEnum(comptime Enum: type, value: anytype) !Enum {
    const info = @typeInfo(Enum).@"enum";
    const Tag = info.tag_type;
    const tag = std.math.cast(Tag, value) orelse return error.InvalidEnumTag;
    inline for (info.fields) |field| {
        if (field.value == tag) {
            return @enumFromInt(tag);
        }
    }
    return error.InvalidEnumTag;
}

pub const Timer = struct {
    started: i96,
    previous: i96,

    pub fn start() !Timer {
        const now = monotonicNanoseconds();
        return .{ .started = now, .previous = now };
    }

    pub fn read(self: *const Timer) u64 {
        return durationSince(self.started);
    }

    pub fn reset(self: *Timer) void {
        const now = monotonicNanoseconds();
        self.started = now;
        self.previous = now;
    }

    pub fn lap(self: *Timer) u64 {
        const now = monotonicNanoseconds();
        const elapsed = durationBetween(self.previous, now);
        self.previous = now;
        return elapsed;
    }

    fn durationSince(started: i96) u64 {
        return durationBetween(started, monotonicNanoseconds());
    }

    fn durationBetween(started: i96, ended: i96) u64 {
        if (ended <= started) return 0;
        return @intCast(ended - started);
    }
};

pub fn randomBytes(buffer: []u8) void {
    io().randomSecure(buffer) catch io().random(buffer);
}

pub const GetEnvVarOwnedError = error{
    OutOfMemory,
    EnvironmentVariableNotFound,
    InvalidWtf8,
};

pub fn getEnvVarOwned(allocator: std.mem.Allocator, key: []const u8) GetEnvVarOwnedError![]u8 {
    const env: std.process.Environ = .{ .block = if (@import("builtin").os.tag == .windows) .global else .empty };
    if (comptime @import("builtin").os.tag == .windows) {
        const key_w = try std.unicode.wtf8ToWtf16LeAllocZ(allocator, key);
        defer allocator.free(key_w);
        const value_w = std.process.Environ.getWindows(env, key_w.ptr) orelse return error.EnvironmentVariableNotFound;
        return std.unicode.wtf16LeToWtf8Alloc(allocator, value_w);
    }
    return env.getAlloc(allocator, key) catch |err| switch (err) {
        error.EnvironmentVariableMissing => error.EnvironmentVariableNotFound,
        error.InvalidWtf8 => error.InvalidWtf8,
        error.OutOfMemory => error.OutOfMemory,
    };
}

pub fn envFlagEnabled(key: []const u8) bool {
    const value = getEnvVarOwned(std.heap.page_allocator, key) catch return false;
    defer std.heap.page_allocator.free(value);

    const trimmed = std.mem.trim(u8, value, &std.ascii.whitespace);
    return std.mem.eql(u8, trimmed, "1") or
        std.ascii.eqlIgnoreCase(trimmed, "true") or
        std.ascii.eqlIgnoreCase(trimmed, "yes") or
        std.ascii.eqlIgnoreCase(trimmed, "on");
}

pub fn unixTimestamp() i64 {
    return std.Io.Clock.real.now(io()).toSeconds();
}

pub const net = struct {
    const std_net = std.Io.net;
    const posix = std.posix;

    pub const RawSocket = posix.socket_t;

    pub const PosixAddress = extern union {
        any: posix.sockaddr,
        in: posix.sockaddr.in,
        in6: posix.sockaddr.in6,
    };

    pub const Address = struct {
        inner: std_net.IpAddress,

        pub fn parseIp(host: []const u8, port: u16) !Address {
            return .{ .inner = try std_net.IpAddress.parse(host, port) };
        }

        pub fn parseIp4(host: []const u8, port: u16) !Address {
            return .{ .inner = try std_net.IpAddress.parseIp4(host, port) };
        }

        pub fn initIp4(bytes: [4]u8, port: u16) Address {
            return .{ .inner = .{ .ip4 = .{ .bytes = bytes, .port = port } } };
        }

        pub fn format(self: Address, writer: *std.Io.Writer) std.Io.Writer.Error!void {
            try self.inner.format(writer);
        }

        pub fn toPosix(self: Address, storage: *PosixAddress) posix.socklen_t {
            return switch (self.inner) {
                .ip4 => |ip4| {
                    storage.in = .{
                        .port = std.mem.nativeToBig(u16, ip4.port),
                        .addr = @bitCast(ip4.bytes),
                    };
                    return @sizeOf(posix.sockaddr.in);
                },
                .ip6 => |ip6| {
                    storage.in6 = .{
                        .port = std.mem.nativeToBig(u16, ip6.port),
                        .flowinfo = ip6.flow,
                        .addr = ip6.bytes,
                        .scope_id = ip6.interface.index,
                    };
                    return @sizeOf(posix.sockaddr.in6);
                },
            };
        }

        pub fn fromPosix(storage: *const PosixAddress) Address {
            return switch (storage.any.family) {
                posix.AF.INET => .{ .inner = .{ .ip4 = .{
                    .port = std.mem.bigToNative(u16, storage.in.port),
                    .bytes = @bitCast(storage.in.addr),
                } } },
                posix.AF.INET6 => .{ .inner = .{ .ip6 = .{
                    .port = std.mem.bigToNative(u16, storage.in6.port),
                    .bytes = storage.in6.addr,
                    .flow = storage.in6.flowinfo,
                    .interface = .{ .index = storage.in6.scope_id },
                } } },
                else => .{ .inner = .{ .ip4 = .loopback(0) } },
            };
        }

        pub fn listen(self: Address, options: anytype) !Server {
            const Options = @TypeOf(options);
            var listen_options: std_net.IpAddress.ListenOptions = .{};
            if (@hasField(Options, "reuse_address")) listen_options.reuse_address = options.reuse_address;
            if (@hasField(Options, "kernel_backlog")) listen_options.kernel_backlog = options.kernel_backlog;
            const server = try self.inner.listen(io(), listen_options);
            return .{ .inner = server };
        }
    };

    pub fn openTcpListener(address: Address, kernel_backlog: u31) !RawSocket {
        var storage: PosixAddress = undefined;
        const len = address.toPosix(&storage);
        const socket = try openSocket(storage.any.family);
        errdefer closeRaw(socket);
        try setReuseAddress(socket);
        try setNonblocking(socket, true);
        try bindRaw(socket, &storage.any, len);
        try listenRaw(socket, kernel_backlog);
        return socket;
    }

    pub fn acceptRaw(listener: RawSocket) !RawSocket {
        if (comptime @import("builtin").os.tag == .windows) {
            const accepted = winsock.accept(socketToInt(listener), null, null);
            if (accepted == invalid_socket) {
                return windowsSocketError();
            }
            return socketFromInt(accepted);
        } else {
            const accepted = std.c.accept(listener, null, null);
            if (accepted == -1) {
                return posixSocketError();
            }
            return @intCast(accepted);
        }
    }

    pub fn closeRaw(socket: RawSocket) void {
        if (comptime @import("builtin").os.tag == .windows) {
            _ = winsock.closesocket(socketToInt(socket));
        } else {
            _ = std.c.close(socket);
        }
    }

    pub fn shutdownRaw(socket: RawSocket) !void {
        if (comptime @import("builtin").os.tag == .windows) {
            if (winsock.shutdown(socketToInt(socket), 0) != 0) {
                return windowsSocketError();
            }
        } else {
            if (std.c.shutdown(socket, 0) != 0) {
                return posixSocketError();
            }
        }
    }

    pub fn sendRaw(socket: RawSocket, data: []const u8) !usize {
        if (comptime @import("builtin").os.tag == .windows) {
            const n = winsock.send(socketToInt(socket), data.ptr, @intCast(data.len), 0);
            if (n < 0) {
                return windowsSocketError();
            }
            return @intCast(n);
        } else {
            const n = std.c.send(socket, data.ptr, data.len, 0);
            if (n < 0) {
                return posixSocketError();
            }
            return @intCast(n);
        }
    }

    pub fn recvRaw(socket: RawSocket, buffer: []u8) !usize {
        if (comptime @import("builtin").os.tag == .windows) {
            const n = winsock.recv(socketToInt(socket), buffer.ptr, @intCast(buffer.len), 0);
            if (n < 0) {
                return windowsSocketError();
            }
            return @intCast(n);
        } else {
            const n = std.c.recv(socket, buffer.ptr, buffer.len, 0);
            if (n < 0) {
                return posixSocketError();
            }
            return @intCast(n);
        }
    }

    pub fn setNonblocking(socket: RawSocket, nonblocking: bool) !void {
        if (comptime @import("builtin").os.tag == .windows) {
            var mode: c_ulong = if (nonblocking) 1 else 0;
            if (winsock.ioctlsocket(socketToInt(socket), FIONBIO, &mode) != 0) {
                return windowsSocketError();
            }
        } else {
            const flags = std.c.fcntl(socket, std.c.F.GETFL, 0);
            if (flags == -1) return posixSocketError();
            const nonblock_flag: c_int = @bitCast(posix.O{ .NONBLOCK = true });
            const next_flags = if (nonblocking) flags | nonblock_flag else flags & ~nonblock_flag;
            if (std.c.fcntl(socket, std.c.F.SETFL, next_flags) == -1) {
                return posixSocketError();
            }
        }
    }

    pub fn getPeerAddress(socket: RawSocket) !Address {
        var storage: PosixAddress = undefined;
        var len: posix.socklen_t = @sizeOf(PosixAddress);
        if (comptime @import("builtin").os.tag == .windows) {
            if (winsock.getpeername(socketToInt(socket), &storage.any, &len) != 0) {
                return windowsSocketError();
            }
        } else {
            if (std.c.getpeername(socket, &storage.any, &len) != 0) {
                return posixSocketError();
            }
        }
        return Address.fromPosix(&storage);
    }

    fn openSocket(family: posix.sa_family_t) !RawSocket {
        if (comptime @import("builtin").os.tag == .windows) {
            const socket = winsock.socket(family, posix.SOCK.STREAM, posix.IPPROTO.TCP);
            if (socket == invalid_socket) {
                return windowsSocketError();
            }
            return socketFromInt(socket);
        } else {
            const socket = std.c.socket(family, posix.SOCK.STREAM, posix.IPPROTO.TCP);
            if (socket == -1) {
                return posixSocketError();
            }
            return @intCast(socket);
        }
    }

    fn setReuseAddress(socket: RawSocket) !void {
        const value: c_int = 1;
        if (comptime @import("builtin").os.tag == .windows) {
            if (winsock.setsockopt(socketToInt(socket), posix.SOL.SOCKET, posix.SO.REUSEADDR, &value, @sizeOf(c_int)) != 0) {
                return windowsSocketError();
            }
        } else {
            if (std.c.setsockopt(socket, posix.SOL.SOCKET, posix.SO.REUSEADDR, &value, @sizeOf(c_int)) != 0) {
                return posixSocketError();
            }
        }
    }

    fn bindRaw(socket: RawSocket, address: *const posix.sockaddr, len: posix.socklen_t) !void {
        if (comptime @import("builtin").os.tag == .windows) {
            if (winsock.bind(socketToInt(socket), address, len) != 0) {
                return windowsSocketError();
            }
        } else {
            if (std.c.bind(socket, address, len) != 0) {
                return posixSocketError();
            }
        }
    }

    fn listenRaw(socket: RawSocket, kernel_backlog: u31) !void {
        if (comptime @import("builtin").os.tag == .windows) {
            if (winsock.listen(socketToInt(socket), kernel_backlog) != 0) {
                return windowsSocketError();
            }
        } else {
            if (std.c.listen(socket, kernel_backlog) != 0) {
                return posixSocketError();
            }
        }
    }

    const invalid_socket = ~@as(usize, 0);
    const FIONBIO: c_long = -2147195266;
    const WSAEINTR = 10004;
    const WSAEINVAL = 10022;
    const WSAENOTSOCK = 10038;
    const WSAEWOULDBLOCK = 10035;
    const WSAENETDOWN = 10050;
    const WSAECONNABORTED = 10053;
    const WSAECONNRESET = 10054;
    const WSAESHUTDOWN = 10058;

    const winsock = struct {
        extern "ws2_32" fn socket(af: c_int, socket_type: c_int, protocol: c_int) callconv(.c) usize;
        extern "ws2_32" fn bind(s: usize, name: *const posix.sockaddr, namelen: posix.socklen_t) callconv(.c) c_int;
        extern "ws2_32" fn listen(s: usize, backlog: c_int) callconv(.c) c_int;
        extern "ws2_32" fn accept(s: usize, addr: ?*posix.sockaddr, addrlen: ?*posix.socklen_t) callconv(.c) usize;
        extern "ws2_32" fn closesocket(s: usize) callconv(.c) c_int;
        extern "ws2_32" fn shutdown(s: usize, how: c_int) callconv(.c) c_int;
        extern "ws2_32" fn send(s: usize, buf: [*]const u8, len: c_int, flags: c_int) callconv(.c) c_int;
        extern "ws2_32" fn recv(s: usize, buf: [*]u8, len: c_int, flags: c_int) callconv(.c) c_int;
        extern "ws2_32" fn ioctlsocket(s: usize, cmd: c_long, argp: *c_ulong) callconv(.c) c_int;
        extern "ws2_32" fn setsockopt(s: usize, level: c_int, optname: c_int, optval: *const c_int, optlen: c_int) callconv(.c) c_int;
        extern "ws2_32" fn getpeername(s: usize, name: *posix.sockaddr, namelen: *posix.socklen_t) callconv(.c) c_int;
        extern "ws2_32" fn WSAGetLastError() callconv(.c) c_int;
    };

    fn socketToInt(socket: RawSocket) usize {
        return if (@typeInfo(RawSocket) == .pointer) @intFromPtr(socket) else @intCast(socket);
    }

    fn socketFromInt(socket: usize) RawSocket {
        return if (@typeInfo(RawSocket) == .pointer) @ptrFromInt(socket) else @intCast(socket);
    }

    fn windowsSocketError() anyerror {
        return switch (winsock.WSAGetLastError()) {
            WSAEWOULDBLOCK => error.WouldBlock,
            WSAECONNABORTED => error.ConnectionAborted,
            WSAECONNRESET => error.ConnectionResetByPeer,
            WSAESHUTDOWN => error.SocketNotListening,
            WSAEINVAL, WSAENOTSOCK => error.SocketNotListening,
            WSAENETDOWN => error.NetworkDown,
            WSAEINTR => error.Interrupted,
            else => error.Unexpected,
        };
    }

    fn posixSocketError() anyerror {
        return switch (std.c.errno(-1)) {
            .AGAIN => error.WouldBlock,
            .INTR => error.Interrupted,
            .CONNABORTED => error.ConnectionAborted,
            .CONNRESET => error.ConnectionResetByPeer,
            .BADF, .INVAL, .NOTSOCK => error.SocketNotListening,
            .NETDOWN => error.NetworkDown,
            else => error.Unexpected,
        };
    }

    pub const Stream = struct {
        inner: std_net.Stream,
        handle: std.posix.socket_t,

        fn wrap(inner: std_net.Stream) Stream {
            return .{ .inner = inner, .handle = inner.socket.handle };
        }

        pub fn close(self: *const Stream) void {
            self.inner.close(io());
        }

        pub fn read(self: *const Stream, buffer: []u8) !usize {
            var slices: [1][]u8 = .{buffer};
            return self.inner.read(io(), &slices);
        }

        pub fn writeAll(self: *const Stream, data: []const u8) !void {
            var buffer: [4096]u8 = undefined;
            var writer_instance = self.inner.writer(io(), &buffer);
            try writer_instance.interface.writeAll(data);
            try writer_instance.interface.flush();
        }

        pub fn shutdown(self: *const Stream, how: std_net.ShutdownHow) !void {
            try self.inner.shutdown(io(), how);
        }

        pub fn reader(self: Stream, buffer: []u8) std_net.Stream.Reader {
            return self.inner.reader(io(), buffer);
        }

        pub fn writer(self: Stream, buffer: []u8) std_net.Stream.Writer {
            return self.inner.writer(io(), buffer);
        }
    };

    pub const Server = struct {
        inner: std_net.Server,

        pub const Connection = struct {
            stream: Stream,
        };

        pub fn accept(self: *Server) !Connection {
            return .{ .stream = Stream.wrap(try self.inner.accept(io())) };
        }

        pub fn deinit(self: *Server) void {
            self.inner.deinit(io());
        }
    };

    pub const AddressList = struct {
        allocator: std.mem.Allocator,
        addrs: []Address,

        pub fn deinit(self: AddressList) void {
            self.allocator.free(self.addrs);
        }
    };

    pub fn tcpConnectToAddress(address: Address) !Stream {
        return Stream.wrap(try address.inner.connect(io(), .{ .mode = .stream }));
    }

    pub fn getAddressList(allocator: std.mem.Allocator, host: []const u8, port: u16) !AddressList {
        const resolved = try std_net.IpAddress.resolve(io(), host, port);
        const addrs = try allocator.alloc(Address, 1);
        addrs[0] = .{ .inner = resolved };
        return .{ .allocator = allocator, .addrs = addrs };
    }
};

pub const fs = struct {
    pub const path = std.Io.Dir.path;
    pub const max_path_bytes = std.Io.Dir.max_path_bytes;

    fn openDirOptions(options: anytype) std.Io.Dir.OpenOptions {
        const Options = @TypeOf(options);
        var result: std.Io.Dir.OpenOptions = .{};
        if (@hasField(Options, "access_sub_paths")) result.access_sub_paths = options.access_sub_paths;
        if (@hasField(Options, "iterate")) result.iterate = options.iterate;
        if (@hasField(Options, "follow_symlinks")) result.follow_symlinks = options.follow_symlinks;
        if (@hasField(Options, "no_follow")) result.follow_symlinks = !options.no_follow;
        return result;
    }

    fn openFileOptions(options: anytype) std.Io.Dir.OpenFileOptions {
        const Options = @TypeOf(options);
        var result: std.Io.Dir.OpenFileOptions = .{};
        if (@hasField(Options, "mode")) result.mode = options.mode;
        if (@hasField(Options, "lock")) result.lock = options.lock;
        if (@hasField(Options, "lock_nonblocking")) result.lock_nonblocking = options.lock_nonblocking;
        if (@hasField(Options, "allow_ctty")) result.allow_ctty = options.allow_ctty;
        if (@hasField(Options, "follow_symlinks")) result.follow_symlinks = options.follow_symlinks;
        if (@hasField(Options, "resolve_beneath")) result.resolve_beneath = options.resolve_beneath;
        return result;
    }

    fn createFileOptions(options: anytype) std.Io.Dir.CreateFileOptions {
        const Options = @TypeOf(options);
        var result: std.Io.Dir.CreateFileOptions = .{};
        if (@hasField(Options, "read")) result.read = options.read;
        if (@hasField(Options, "truncate")) result.truncate = options.truncate;
        if (@hasField(Options, "exclusive")) result.exclusive = options.exclusive;
        if (@hasField(Options, "lock")) result.lock = options.lock;
        if (@hasField(Options, "lock_nonblocking")) result.lock_nonblocking = options.lock_nonblocking;
        if (@hasField(Options, "permissions")) result.permissions = options.permissions;
        if (@hasField(Options, "resolve_beneath")) result.resolve_beneath = options.resolve_beneath;
        return result;
    }

    pub const File = struct {
        inner: std.Io.File,

        pub const Stat = std.Io.File.Stat;
        pub const Kind = std.Io.File.Kind;
        pub const Lock = std.Io.File.Lock;

        pub fn stdout() File {
            return .{ .inner = .stdout() };
        }

        pub fn stderr() File {
            return .{ .inner = .stderr() };
        }

        pub fn stdin() File {
            return .{ .inner = .stdin() };
        }

        pub fn close(self: File) void {
            self.inner.close(io());
        }

        pub fn stat(self: File) !Stat {
            return self.inner.stat(io());
        }

        pub fn writer(self: File, buffer: []u8) std.Io.File.Writer {
            return self.inner.writer(io(), buffer);
        }

        pub fn writerStreaming(self: File, buffer: []u8) std.Io.File.Writer {
            return self.inner.writerStreaming(io(), buffer);
        }

        pub fn reader(self: File, buffer: []u8) std.Io.File.Reader {
            return self.inner.reader(io(), buffer);
        }

        pub fn writeAll(self: File, bytes: []const u8) !void {
            try self.inner.writeStreamingAll(io(), bytes);
        }

        pub fn readToEndAlloc(self: File, allocator: std.mem.Allocator, max_bytes: usize) ![]u8 {
            var buffer: [4096]u8 = undefined;
            var reader_instance = self.inner.reader(io(), &buffer);
            var out: std.ArrayList(u8) = .empty;
            try reader_instance.interface.appendRemaining(allocator, &out, .limited(max_bytes));
            return out.toOwnedSlice(allocator);
        }

        pub fn seekTo(self: File, offset: u64) !void {
            const active_io = io();
            try active_io.vtable.fileSeekTo(active_io.userdata, self.inner, offset);
        }

        pub fn seekFromEnd(self: File, offset: i64) !void {
            const stat_info = try self.stat();
            const base: i128 = @intCast(stat_info.size);
            const target = base + offset;
            if (target < 0) return error.Unseekable;
            try self.seekTo(@intCast(target));
        }
    };

    pub const Dir = struct {
        inner: std.Io.Dir,

        pub const Entry = std.Io.Dir.Entry;
        pub const Iterator = struct {
            inner: std.Io.Dir.Iterator,

            pub fn next(self: *Iterator) !?Entry {
                return self.inner.next(io());
            }
        };

        pub fn close(self: Dir) void {
            self.inner.close(io());
        }

        pub fn openDir(self: Dir, sub_path: []const u8, options: anytype) !Dir {
            return .{ .inner = try self.inner.openDir(io(), sub_path, openDirOptions(options)) };
        }

        pub fn openFile(self: Dir, sub_path: []const u8, options: anytype) !File {
            return .{ .inner = try self.inner.openFile(io(), sub_path, openFileOptions(options)) };
        }

        pub fn createFile(self: Dir, sub_path: []const u8, options: anytype) !File {
            return .{ .inner = try self.inner.createFile(io(), sub_path, createFileOptions(options)) };
        }

        pub fn readFile(self: Dir, sub_path: []const u8, buffer: []u8) ![]u8 {
            var file = try self.openFile(sub_path, .{});
            defer file.close();

            var reader_instance = file.reader(buffer);
            const n = try reader_instance.interface.readSliceShort(buffer);
            return buffer[0..n];
        }

        pub fn deleteFile(self: Dir, sub_path: []const u8) !void {
            try self.inner.deleteFile(io(), sub_path);
        }

        pub fn access(self: Dir, sub_path: []const u8, options: anytype) !void {
            _ = options;
            try self.inner.access(io(), sub_path, .{});
        }

        pub fn deleteTree(self: Dir, sub_path: []const u8) !void {
            try self.inner.deleteTree(io(), sub_path);
        }

        pub fn makePath(self: Dir, sub_path: []const u8) !void {
            try self.inner.createDirPath(io(), sub_path);
        }

        pub fn makeOpenPath(self: Dir, sub_path: []const u8, options: anytype) !Dir {
            return .{ .inner = try self.inner.createDirPathOpen(io(), sub_path, .{ .open_options = openDirOptions(options) }) };
        }

        pub fn statFile(self: Dir, sub_path: []const u8) !std.Io.File.Stat {
            return self.inner.statFile(io(), sub_path, .{});
        }

        pub fn realpathAlloc(self: Dir, allocator: std.mem.Allocator, sub_path: []const u8) ![]u8 {
            const resolved = try self.inner.realPathFileAlloc(io(), sub_path, allocator);
            defer allocator.free(resolved);
            return allocator.dupe(u8, resolved);
        }

        pub fn writeFile(self: Dir, options: anytype) !void {
            const Options = @TypeOf(options);
            const flags = if (@hasField(Options, "flags")) options.flags else .{};
            var file = try self.createFile(options.sub_path, flags);
            defer file.close();
            try file.writeAll(options.data);
        }

        pub fn walk(self: Dir, allocator: std.mem.Allocator) !Walker {
            return .{ .inner = try self.inner.walk(allocator) };
        }

        pub fn iterate(self: Dir) Iterator {
            return .{ .inner = self.inner.iterate() };
        }

        pub fn iterateAssumeFirstIteration(self: Dir) Iterator {
            return .{ .inner = self.inner.iterateAssumeFirstIteration() };
        }
    };

    pub const Walker = struct {
        inner: std.Io.Dir.Walker,

        pub const Entry = std.Io.Dir.Walker.Entry;

        pub fn next(self: *Walker) !?Entry {
            return self.inner.next(io());
        }

        pub fn deinit(self: *Walker) void {
            self.inner.deinit();
        }
    };

    pub fn cwd() Dir {
        return .{ .inner = .cwd() };
    }

    pub fn openDirAbsolute(absolute_path: []const u8, options: anytype) !Dir {
        return .{ .inner = try std.Io.Dir.openDirAbsolute(io(), absolute_path, openDirOptions(options)) };
    }

    pub fn openFileAbsolute(absolute_path: []const u8, options: anytype) !File {
        return .{ .inner = try std.Io.Dir.openFileAbsolute(io(), absolute_path, openFileOptions(options)) };
    }

    pub fn createFileAbsolute(absolute_path: []const u8, options: anytype) !File {
        return .{ .inner = try std.Io.Dir.createFileAbsolute(io(), absolute_path, createFileOptions(options)) };
    }

    pub fn deleteFileAbsolute(absolute_path: []const u8) !void {
        try std.Io.Dir.deleteFileAbsolute(io(), absolute_path);
    }

    pub fn makeDirAbsolute(absolute_path: []const u8) !void {
        try std.Io.Dir.createDirAbsolute(io(), absolute_path, .default_dir);
    }

    pub fn accessAbsolute(absolute_path: []const u8, options: anytype) !void {
        _ = options;
        try std.Io.Dir.accessAbsolute(io(), absolute_path, .{});
    }

    pub fn realpathAlloc(allocator: std.mem.Allocator, sub_path: []const u8) ![]u8 {
        if (path.isAbsolute(sub_path)) {
            const resolved = try std.Io.Dir.realPathFileAbsoluteAlloc(io(), sub_path, allocator);
            defer allocator.free(resolved);
            return allocator.dupe(u8, resolved);
        }
        return cwd().realpathAlloc(allocator, sub_path);
    }

    pub fn getAppDataDir(allocator: std.mem.Allocator, appname: []const u8) ![]u8 {
        const env: std.process.Environ = .{ .block = if (@import("builtin").os.tag == .windows) .global else .empty };
        const root = env.getAlloc(allocator, if (@import("builtin").os.tag == .windows) "LOCALAPPDATA" else "HOME") catch |err| switch (err) {
            error.EnvironmentVariableMissing => return err,
            else => |e| return e,
        };
        defer allocator.free(root);
        return path.join(allocator, &.{ root, appname });
    }
};
