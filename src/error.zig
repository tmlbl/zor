const std = @import("std");

pub const RegistryError = struct {
    /// The code field MUST be a unique identifier, containing only uppercase
    /// alphabetic characters and underscores.
    code: []const u8, // readable string or MAY be empty.
    message: []const u8,
};
