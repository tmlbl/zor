const std = @import("std");

const uuid = @import("./uuid.zig");

fn initDir(dir: []const u8) !void {
    if (std.fs.makeDirAbsolute(dir)) |_| {} else |err| switch (err) {
        error.PathAlreadyExists => {},
        else => |e| return e,
    }
}

pub const LocalStorage = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}),
    root: []const u8,
    blobDir: std.fs.Dir,
    uploadDir: std.fs.Dir,

    pub fn init(dir: []const u8) !LocalStorage {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};

        const blobDirPath = try std.fs.path.join(gpa.allocator(), &[_][]const u8{ dir, "blobs" });
        try initDir(blobDirPath);
        const blobDir = try std.fs.openDirAbsolute(blobDirPath, .{});

        const uploadDirPath = try std.fs.path.join(gpa.allocator(), &[_][]const u8{ dir, "uploads" });
        try initDir(uploadDirPath);
        const uploadDir = try std.fs.openDirAbsolute(uploadDirPath, .{});

        return LocalStorage{
            .gpa = gpa,
            .root = dir,
            .blobDir = blobDir,
            .uploadDir = uploadDir,
        };
    }

    pub fn deinit(self: *LocalStorage) !void {
        try self.gpa.deinit();
    }

    pub fn has(self: *LocalStorage, sum: []const u8) bool {
        const stat = self.blobDir.statFile(sum) catch {
            return false;
        };
        return stat.kind == std.fs.File.Kind.file;
    }

    pub fn createUpload(self: *LocalStorage) !void {
        const a = self.gpa.allocator();

        const id = uuid.newV4();
        var path = try std.fmt.allocPrint(a, "{}", .{id});
        std.log.debug("creating upload at {s}", .{path});

        const ufile = try self.uploadDir.createFile(path, .{});
        ufile.close();

        a.free(path);
    }
};
