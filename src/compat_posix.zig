const std = @import("std");
const posix = std.posix;

pub const WriteError = posix.UnexpectedError || error{
    WouldBlock,
    BrokenPipe,
    ConnectionResetByPeer,
    SystemResources,
    InputOutput,
    AccessDenied,
    SocketUnconnected,
};

pub const FcntlError = posix.UnexpectedError || error{
    AccessDenied,
    BadFileDescriptor,
    WouldBlock,
};

pub const ShutdownError = posix.UnexpectedError || error{
    SocketNotConnected,
    FileDescriptorNotASocket,
};

pub fn close(fd: posix.fd_t) void {
    _ = std.c.close(fd);
}

pub fn write(fd: posix.fd_t, data: []const u8) WriteError!usize {
    if (data.len == 0) return 0;
    while (true) {
        const rc = std.c.write(fd, data.ptr, data.len);
        switch (posix.errno(rc)) {
            .SUCCESS => return @intCast(rc),
            .INTR => continue,
            .AGAIN => return error.WouldBlock,
            .PIPE => return error.BrokenPipe,
            .CONNRESET => return error.ConnectionResetByPeer,
            .NOBUFS, .NOMEM => return error.SystemResources,
            .IO => return error.InputOutput,
            .NOTCONN => return error.SocketUnconnected,
            .BADF => return error.AccessDenied,
            else => |err| return posix.unexpectedErrno(err),
        }
    }
}

pub fn fcntlGetFlags(fd: posix.fd_t) FcntlError!u32 {
    while (true) {
        const rc = std.c.fcntl(fd, posix.F.GETFL, 0);
        switch (posix.errno(rc)) {
            .SUCCESS => return @intCast(rc),
            .INTR => continue,
            .ACCES, .PERM => return error.AccessDenied,
            .BADF => return error.BadFileDescriptor,
            .AGAIN => return error.WouldBlock,
            else => |err| return posix.unexpectedErrno(err),
        }
    }
}

pub fn fcntlSetFlags(fd: posix.fd_t, flags: u32) FcntlError!void {
    while (true) {
        const rc = std.c.fcntl(fd, posix.F.SETFL, flags);
        switch (posix.errno(rc)) {
            .SUCCESS => return,
            .INTR => continue,
            .ACCES, .PERM => return error.AccessDenied,
            .BADF => return error.BadFileDescriptor,
            .AGAIN => return error.WouldBlock,
            else => |err| return posix.unexpectedErrno(err),
        }
    }
}

pub fn shutdown(fd: posix.fd_t, how: std.Io.net.ShutdownHow) ShutdownError!void {
    const c_how: c_int = switch (how) {
        .recv => posix.SHUT.RD,
        .send => posix.SHUT.WR,
        .both => posix.SHUT.RDWR,
    };
    while (true) {
        const rc = std.c.shutdown(fd, c_how);
        switch (posix.errno(rc)) {
            .SUCCESS => return,
            .INTR => continue,
            .NOTCONN => return error.SocketNotConnected,
            .NOTSOCK => return error.FileDescriptorNotASocket,
            else => |err| return posix.unexpectedErrno(err),
        }
    }
}
