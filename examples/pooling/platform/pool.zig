//! Small loopback-only pool. No Redis protocol knowledge lives here.
//! Host calls are serialized; this demo is not a concurrent application server.
const std = @import("std");
pub const c = @cImport({
    // glibc's fortified variadic open/openat wrappers cannot be translated by
    // this Zig release in optimized builds. We use neither function; disable
    // those C-only wrappers for this import, retaining Zig ReleaseSafe checks.
    @cUndef("_FORTIFY_SOURCE");
    @cInclude("sys/socket.h");
    @cInclude("netinet/in.h");
    @cInclude("arpa/inet.h");
    @cInclude("poll.h");
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
    @cInclude("time.h");
    @cInclude("errno.h");
    @cInclude("signal.h");
    @cInclude("stdlib.h");
});

pub const max_slots = 16;
const Slot = struct { fd: c_int = -1, lease: u64 = 0, poisoned: bool = false };
pub const Pool = struct {
    port: u16 = 0,
    limit: usize = 0,
    closed: bool = true,
    next_lease: u64 = 1,
    slots: [max_slots]Slot = [_]Slot{.{}} ** max_slots,

    pub fn init(port: u16, limit: usize) !Pool {
        if (port == 0 or limit == 0 or limit > max_slots) return error.InvalidSettings;
        return .{ .port = port, .limit = limit, .closed = false };
    }

    pub fn close(self: *Pool) void {
        for (&self.slots) |*slot| self.discard(slot);
        self.closed = true;
    }

    fn discard(_: *Pool, slot: *Slot) void {
        if (slot.fd >= 0) _ = c.close(slot.fd);
        slot.* = .{};
    }

    pub fn acquire(self: *Pool, timeout_ms: u64) u64 {
        if (self.closed or timeout_ms == 0 or timeout_ms > 5_000) return 0;
        const until = deadline(timeout_ms);
        while (now() < until) {
            for (self.slots[0..self.limit]) |*slot| {
                if (slot.lease != 0) continue;
                if (self.next_lease == std.math.maxInt(u64)) return 0;
                if (slot.fd < 0) slot.fd = dial(self.port, until) catch return 0;
                slot.lease = self.next_lease;
                self.next_lease += 1;
                return slot.lease;
            }
            // A bounded wait, not an unbounded queue. In this single-threaded
            // demo, nested exhaustion times out rather than making progress.
            const delay = c.timespec{ .tv_sec = 0, .tv_nsec = 1_000_000 };
            _ = c.nanosleep(&delay, null);
        }
        return 0;
    }

    fn lookup(self: *Pool, lease: u64) ?*Slot {
        if (self.closed or lease == 0) return null;
        for (self.slots[0..self.limit]) |*slot| {
            if (slot.lease == lease) return slot;
        }
        return null;
    }

    pub fn finish(self: *Pool, lease: u64, reuse: bool) bool {
        const slot = self.lookup(lease) orelse return false;
        if (reuse and !slot.poisoned) slot.lease = 0 else self.discard(slot);
        return true;
    }

    pub fn read(self: *Pool, lease: u64, bytes: []u8, timeout_ms: u64) !usize {
        const slot = self.lookup(lease) orelse return error.InvalidLease;
        if (slot.poisoned) return error.InvalidLease;
        if (bytes.len == 0 or bytes.len > 1_048_576 or timeout_ms == 0 or timeout_ms > 5_000) return error.InvalidLimit;
        errdefer slot.poisoned = true;
        const until = deadline(timeout_ms);
        while (true) {
            try ready(slot.fd, c.POLLIN, until);
            const n = c.recv(slot.fd, bytes.ptr, bytes.len, 0);
            if (n >= 0) {
                if (n == 0) slot.poisoned = true;
                return @intCast(n);
            }
            if (!retryable()) return error.IoFailed;
        }
    }

    pub fn write(self: *Pool, lease: u64, bytes: []const u8, timeout_ms: u64) !void {
        const slot = self.lookup(lease) orelse return error.InvalidLease;
        if (slot.poisoned) return error.InvalidLease;
        if (bytes.len > 16 * 1024 * 1024 or timeout_ms == 0 or timeout_ms > 5_000) return error.InvalidLimit;
        errdefer slot.poisoned = true;
        const until = deadline(timeout_ms);
        var offset: usize = 0;
        while (offset < bytes.len) {
            try ready(slot.fd, c.POLLOUT, until);
            const n = c.send(slot.fd, bytes[offset..].ptr, bytes.len - offset, 0);
            if (n > 0) offset += @intCast(n) else if (n == 0 or !retryable()) return error.IoFailed;
        }
    }
};

fn errnoValue() c_int {
    return if (@import("builtin").os.tag == .macos) c.__error().* else c.__errno_location().*;
}
fn retryable() bool {
    const e = errnoValue();
    return e == c.EINTR or e == c.EAGAIN or e == c.EWOULDBLOCK;
}
fn now() i64 {
    var ts: c.timespec = undefined;
    if (c.clock_gettime(c.CLOCK_MONOTONIC, &ts) != 0) @panic("monotonic clock unavailable");
    return @as(i64, @intCast(ts.tv_sec)) * 1000 + @divTrunc(@as(i64, @intCast(ts.tv_nsec)), 1_000_000);
}
fn deadline(ms: u64) i64 {
    return now() + @as(i64, @intCast(ms));
}
fn ready(fd: c_int, events: c_short, until: i64) !void {
    while (true) {
        const remaining = until - now();
        if (remaining <= 0) return error.TimedOut;
        var p = c.pollfd{ .fd = fd, .events = events, .revents = 0 };
        const n = c.poll(&p, 1, @intCast(remaining));
        if (n > 0) {
            if (p.revents & c.POLLNVAL != 0) return error.IoFailed;
            return;
        }
        if (n == 0) return error.TimedOut;
        if (errnoValue() != c.EINTR) return error.IoFailed;
    }
}
fn dial(port: u16, until: i64) !c_int {
    const fd = c.socket(c.AF_INET, c.SOCK_STREAM, 0);
    if (fd < 0) return error.IoFailed;
    errdefer _ = c.close(fd);
    if (c.fcntl(fd, c.F_SETFL, @as(c_int, c.O_NONBLOCK)) < 0) return error.IoFailed;
    if (c.fcntl(fd, c.F_SETFD, @as(c_int, c.FD_CLOEXEC)) < 0) return error.IoFailed;
    var addr = std.mem.zeroes(c.sockaddr_in);
    addr.sin_family = c.AF_INET;
    addr.sin_port = c.htons(port);
    addr.sin_addr.s_addr = c.htonl(0x7f000001);
    if (@import("builtin").os.tag == .macos) addr.sin_len = @sizeOf(c.sockaddr_in);
    if (c.connect(fd, @ptrCast(&addr), @sizeOf(c.sockaddr_in)) != 0) {
        const e = errnoValue();
        if (e != c.EINPROGRESS and e != c.EINTR) return error.IoFailed;
        try ready(fd, c.POLLOUT, until);
        var socket_error: c_int = 0;
        var size: c.socklen_t = @sizeOf(c_int);
        if (c.getsockopt(fd, c.SOL_SOCKET, c.SO_ERROR, &socket_error, &size) != 0 or socket_error != 0) return error.IoFailed;
    }
    return fd;
}

test "settings and stale lease checks" {
    try std.testing.expectError(error.InvalidSettings, Pool.init(0, 1));
    try std.testing.expectError(error.InvalidSettings, Pool.init(6379, 17));
    var pool = try Pool.init(6379, 1);
    defer pool.close();
    try std.testing.expect(!pool.finish(0, true));
    try std.testing.expectError(error.InvalidLease, pool.write(1, "x", 1));
    pool.slots[0].lease = 1;
    try std.testing.expect(pool.finish(1, true));
    pool.slots[0].lease = 2;
    try std.testing.expect(!pool.finish(1, true));
    try std.testing.expectError(error.InvalidLease, pool.write(1, "x", 1));
    try std.testing.expectEqual(@as(u64, 0), pool.acquire(1));
    pool.close();
    try std.testing.expectEqual(@as(u64, 0), pool.acquire(1));
}

test "poisoned leases are discarded even when caller requests reuse" {
    var pool = try Pool.init(6379, 1);
    pool.slots[0].lease = 1;
    pool.slots[0].poisoned = true;
    try std.testing.expect(pool.finish(1, true));
    try std.testing.expectEqual(@as(c_int, -1), pool.slots[0].fd);
    try std.testing.expectEqual(@as(u64, 0), pool.slots[0].lease);
}
