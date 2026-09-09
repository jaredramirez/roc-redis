const std = @import("std");
const abi = @import("abi");
const pools = @import("pool.zig");
const c = pools.c;

// One pool per application is intentional in this small demo. Tokens never
// recycle, and closing the pool does not allow creation of a new one.
var pool: ?pools.Pool = null;
var env: u8 = 0;
var context = abi.RocHost{
    .env = &env,
    .roc_alloc = allocCallback,
    .roc_dealloc = freeCallback,
    .roc_realloc = reallocCallback,
    .roc_dbg = debugCallback,
    .roc_expect_failed = fatalCallback,
    .roc_crashed = fatalCallback,
};

fn log(bytes: []const u8) void {
    _ = c.write(2, bytes.ptr, bytes.len);
    _ = c.write(2, "\n", 1);
}
fn fatal(bytes: []const u8) noreturn {
    log(bytes);
    if (pool) |*p| p.close();
    c.exit(1);
}
pub const panic = std.debug.FullPanic(panicImpl);
fn panicImpl(message: []const u8, _: ?usize) noreturn {
    fatal(message);
}

// These are host allocator bookkeeping headers, not manually specified Roc
// value layouts. Roc's allocation/refcount layouts come from generated glue.
export fn roc_alloc(length: usize, requested_alignment: usize) callconv(.c) ?*anyopaque {
    const alignment = @max(requested_alignment, @alignOf(usize));
    if (!std.math.isPowerOfTwo(alignment)) fatal("invalid allocation alignment");
    const overhead = std.math.add(usize, alignment, 2 * @sizeOf(usize)) catch fatal("allocation overflow");
    const total = std.math.add(usize, length, overhead) catch fatal("allocation overflow");
    const raw = c.malloc(total) orelse fatal("out of memory");
    const address = std.mem.alignForward(usize, @intFromPtr(raw) + 2 * @sizeOf(usize), alignment);
    const header: [*]usize = @ptrFromInt(address - 2 * @sizeOf(usize));
    header[0] = @intFromPtr(raw);
    header[1] = length;
    return @ptrFromInt(address);
}
export fn roc_dealloc(ptr: ?*anyopaque, _: usize) callconv(.c) void {
    const address = @intFromPtr(ptr orelse return);
    const header: [*]usize = @ptrFromInt(address - 2 * @sizeOf(usize));
    c.free(@ptrFromInt(header[0]));
}
export fn roc_realloc(ptr: ?*anyopaque, length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    const old = ptr orelse return roc_alloc(length, alignment);
    const header: [*]usize = @ptrFromInt(@intFromPtr(old) - 2 * @sizeOf(usize));
    const result = roc_alloc(length, alignment).?;
    const count = @min(header[1], length);
    @memcpy(@as([*]u8, @ptrCast(result))[0..count], @as([*]const u8, @ptrCast(old))[0..count]);
    roc_dealloc(old, alignment);
    return result;
}
export fn roc_dbg(bytes: [*]const u8, len: usize) callconv(.c) void {
    log(bytes[0..len]);
}
export fn roc_expect_failed(bytes: [*]const u8, len: usize) callconv(.c) void {
    fatal(bytes[0..len]);
}
export fn roc_crashed(bytes: [*]const u8, len: usize) callconv(.c) void {
    fatal(bytes[0..len]);
}
fn allocCallback(_: *abi.RocHost, n: usize, a: usize) callconv(.c) ?*anyopaque {
    return roc_alloc(n, a);
}
fn freeCallback(_: *abi.RocHost, p: *anyopaque, a: usize) callconv(.c) void {
    roc_dealloc(p, a);
}
fn reallocCallback(_: *abi.RocHost, p: *anyopaque, n: usize, a: usize) callconv(.c) ?*anyopaque {
    return roc_realloc(p, n, a);
}
fn debugCallback(_: *abi.RocHost, p: [*]const u8, n: usize) callconv(.c) void {
    roc_dbg(p, n);
}
fn fatalCallback(_: *abi.RocHost, p: [*]const u8, n: usize) callconv(.c) void {
    roc_crashed(p, n);
}

export fn pool_create(port: u16, limit: u64) callconv(.c) u64 {
    if (pool != null or limit > pools.max_slots) return 0;
    pool = pools.Pool.init(port, @intCast(limit)) catch return 0;
    return 1;
}
export fn pool_acquire(id: u64, ms: u64) callconv(.c) u64 {
    if (id != 1) return 0;
    if (pool) |*p| return p.acquire(ms);
    return 0;
}
export fn pool_finish(id: u64, reuse: bool) callconv(.c) bool {
    if (pool) |*p| return p.finish(id, reuse);
    return false;
}
fn code(err: anyerror) u8 {
    return switch (err) {
        error.InvalidLease => 1,
        error.TimedOut => 2,
        error.InvalidLimit => 4,
        else => 3,
    };
}
export fn pool_read(id: u64, limit: u64, ms: u64) callconv(.c) abi.HostRead {
    if (limit == 0 or limit > 1_048_576) return .{ .bytes = .empty(), .code = 4 };
    const p = if (pool) |*p| p else return .{ .bytes = .empty(), .code = 1 };
    const buffer = c.malloc(@intCast(limit)) orelse fatal("out of memory");
    defer c.free(buffer);
    const bytes = @as([*]u8, @ptrCast(buffer))[0..@intCast(limit)];
    const n = p.read(id, bytes, ms) catch |err| return .{ .bytes = .empty(), .code = code(err) };
    return .{ .bytes = abi.RocListWith(u8, false).fromSlice(bytes[0..n], &context), .code = 0 };
}
export fn pool_write(id: u64, bytes: abi.RocListWith(u8, false), ms: u64) callconv(.c) u8 {
    defer bytes.decref(&context);
    const p = if (pool) |*p| p else return 1;
    p.write(id, bytes.items(), ms) catch |err| return code(err);
    return 0;
}
export fn pool_close(id: u64) callconv(.c) bool {
    if (id != 1) return false;
    if (pool) |*p| {
        if (p.closed) return false;
        p.close();
        return true;
    }
    return false;
}
export fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int {
    if (argc != 3 or !std.mem.eql(u8, std.mem.span(argv[1]), "127.0.0.1")) {
        log("usage: pooled-redis 127.0.0.1 <local-redis-port>");
        return 2;
    }
    const port = std.fmt.parseInt(u16, std.mem.span(argv[2]), 10) catch return 2;
    _ = c.signal(c.SIGPIPE, ignoreSignal);
    defer if (pool) |*p| p.close();
    const okay = abi.roc_main(port);
    log(if (okay) "Pool demo passed: reuse, discard, stale aliases, capacity, and callback cleanup" else "Pool demo failed");
    return if (okay) 0 else 1;
}
fn ignoreSignal(_: c_int) callconv(.c) void {}
