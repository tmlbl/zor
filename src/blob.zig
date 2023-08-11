const std = @import("std");

pub const LocalStorage = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}),
    root: []const u8,

    pub fn init(dir: []const u8) LocalStorage {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        return LocalStorage{
            .gpa = gpa,
            .root = dir,
        };
    }

    pub fn deinit(self: *LocalStorage) void {
        _ = self;
    }

    pub fn has(self: *LocalStorage, sum: []const u8) !bool {
        const path = try std.fmt.allocPrint(self.gpa.allocator(), "{s}/{s}", .{ self.root, sum });
        // var stat = std.os.Stat.init();
        // std.os.system.stat(path, &stat);
        std.log.debug("Checking blob path {s}", .{path});

        return true;
    }
};
