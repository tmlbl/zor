const std = @import("std");

pub const Memberlist = struct {
    last_updated: i128,

    pub fn new() Memberlist {
        return Memberlist{
            .last_updated = std.time.nanoTimestamp(),
        };
    }
};
