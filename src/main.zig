const std = @import("std");
const httpz = @import("httpz");

const gossip = @import("./gossip.zig");
const errors = @import("./error.zig");
const blob = @import("./blob.zig");

const Config = struct {
    port: u16,
};

const App = struct {
    a: std.mem.Allocator,
    store: blob.LocalStorage,
    config: Config,
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
        .a = gpa.allocator(),
        .store = store,
        .config = Config{
            .port = 5882,
        },
    };

    const stype = httpz.ServerCtx(*App, *App);
    var server = try stype.init(allocator, .{ .port = app.config.port }, &app);

    server.notFound(notFound);

    // server.errorHandler(errorHandler);

    var router = server.router();

    router.get("/v2", v2);
    router.head("/v2/:repo/blobs/:sum", headBlobs);
    router.post("/v2/:repo/blobs/uploads", createUpload);
    router.patch("/v2/:repo/blobs/uploads/:id", uploadBlob);

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
    const repo = req.params.get("repo").?;
    const id = try app.store.createUpload(res.arena);
    const host = req.headers.get("host").?;

    const loc = try std.fmt.allocPrint(res.arena, "http://{s}/v2/{s}/blobs/uploads/{s}", .{
        host,
        repo,
        id,
    });
    // defer app.a.free(loc);
    res.headers.add("Location", loc);

    const idStr = try std.fmt.allocPrint(res.arena, "{s}", .{id});
    res.headers.add("Docker-Upload-Uuid", idStr);

    res.headers.add("Range", "0-0");

    res.status = 202; // Accepted
}

fn uploadBlob(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    _ = res;
    const repo = req.params.get("repo").?;
    _ = repo;
    const id = req.params.get("id").?;

    // open the upload file
    const file = try app.store.uploadDir.openFile(id, .{
        .mode = std.fs.File.OpenMode.write_only,
    });

    if (try req.body()) |body| {
        const end = try file.getEndPos();
        try file.seekTo(end);
        try file.writeAll(body);
    } else {
        std.log.debug("didn't write anything...", .{});
    }

    file.close();
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
