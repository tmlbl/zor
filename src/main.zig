const std = @import("std");
const httpz = @import("httpz");

const gossip = @import("./gossip.zig");
const errors = @import("./error.zig");
const blob = @import("./blob.zig");

const App = struct {
    store: blob.LocalStorage,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var app = App{
        .store = blob.LocalStorage.init("/tmp/zor"),
    };

    const stype = httpz.ServerCtx(*App, *App);
    var server = try stype.init(allocator, .{ .port = 5882 }, &app);

    server.notFound(notFound);

    // server.errorHandler(errorHandler);

    var router = server.router();

    router.get("/v2", v2);
    router.head("/v2/:repo/blobs/:sum", headBlobs);

    try server.listen();
}

fn headBlobs(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const repo = req.params.get("repo").?;
    const sum = req.params.get("sum").?;
    const has = try app.store.has(sum);
    if (!has) {}
    std.log.debug("{s} {s}", .{ repo, sum });
    _ = res;
}

fn notFound(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    _ = app;
    res.status = 404;
    const err = errors.RegistryError{
        .code = "NOTFOUND",
        .message = "Not Found",
    };
    std.log.warn("Not found for {} {s}", .{ req.method, req.url.path });
    try res.json(err, .{});
}

// fn errorHandler(_: *httpz.Request, res: *httpz.Response, err: anyerror) void {
//     res.status = 500;
//     const re = errors.RegistryError{
//         .code = "ERROR",
//         .message = "Ahhhh",
//     };
//     std.log.warn("An error occurred: {}", .{err});
//     res.json(re, .{}) catch unreachable;
// }

fn v2(_: *App, _: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = "true";
}
