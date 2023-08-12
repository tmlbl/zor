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
    defer {
        const deinit_status = gpa.deinit();
        _ = deinit_status;
        //fail test; can't try in defer as defer is executed after we return
        // if (deinit_status == .leak) expect(false) catch @panic("TEST FAIL");
    }

    const allocator = gpa.allocator();

    const store = try blob.LocalStorage.init("/tmp/zor");

    var app = App{
        .store = store,
    };

    const stype = httpz.ServerCtx(*App, *App);
    var server = try stype.init(allocator, .{ .port = 5882 }, &app);

    server.notFound(notFound);

    // server.errorHandler(errorHandler);

    var router = server.router();

    router.get("/v2", v2);
    router.head("/v2/:repo/blobs/:sum", headBlobs);
    router.post("/v2/:repo/blobs/uploads", createUpload);

    try server.listen();
}

fn headBlobs(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const sum = req.params.get("sum").?;
    if (!app.store.has(sum)) {
        std.log.debug("blob {s} not found", .{sum});
        res.status = 404;
        return;
    } else {
        std.log.debug("blob {s} found OK", .{sum});
    }
}

fn createUpload(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    _ = res;
    _ = req;
    try app.store.createUpload();
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
