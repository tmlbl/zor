const std = @import("std");

pub const LocalStorage = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}),
    root: std.fs.Dir,

    pub fn init(dir: []const u8) !LocalStorage {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        try std.fs.makeDirAbsolute(dir);
        var root = try std.fs.openDirAbsolute(dir, .{});
        return LocalStorage{
            .gpa = gpa,
            .root = root,
        };
    }

    pub fn deinit(self: *LocalStorage) void {
        _ = self;
    }

    pub fn has(self: *LocalStorage, sum: []const u8) bool {
        try self.root.statFile(sum) catch {
            return false;
        };
        return true;
    }
};
