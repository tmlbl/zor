const std = @import("std");

pub const LocalStorage = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}),
    root: std.fs.Dir,

    pub fn init(dir: []const u8) !LocalStorage {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        if (std.fs.makeDirAbsolute(dir)) |_| {} else |err| switch (err) {
            error.PathAlreadyExists => {},
            else => |e| return e,
        }
        const root = try std.fs.openDirAbsolute(dir, .{});
        return LocalStorage{
            .gpa = gpa,
            .root = root,
        };
    }

    pub fn deinit(self: *LocalStorage) void {
        _ = self;
    }

    pub fn has(self: *LocalStorage, sum: []const u8) bool {
        const stat = self.root.statFile(sum) catch {
            return false;
        };
        return stat.kind == std.fs.File.Kind.file;
    }
};
