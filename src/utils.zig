const std = @import("std");

const Reader = std.io.Reader;
const BufferedReader = std.io.BufferedReader;
const File = std.fs.File;
const FileReader = Reader(File, File.ReadError, File.read);
const FileBufferedReader = BufferedReader(4096, FileReader);

pub const LineReader = struct {
	file: std.fs.File,
	reader: *FileBufferedReader,
	stream: Reader(*FileBufferedReader, FileReader.Error, FileBufferedReader.read),
	allocator: std.mem.Allocator,
	buf: *[1024]u8,

	const Self = @This();

	pub fn open(path: []const u8, allocator: std.mem.Allocator) !Self {
    var file = try std.fs.cwd().openFile(path, .{});

    var reader = try allocator.create(FileBufferedReader);
	  reader.* = std.io.bufferedReader(file.reader());
	  var stream = reader.reader();

	  var buf = try allocator.create([1024]u8);

	  return .{
	  	.file = file,
	  	.stream = stream,
	  	.reader = reader,
	  	.allocator = allocator,
	  	.buf = buf,
	  };
	}

	pub fn next(self: *Self) !?[]const u8 {
	  var fbs = std.io.fixedBufferStream(self.buf);
	  self.stream.streamUntilDelimiter(fbs.writer(), '\n', 1024) catch |err| switch (err) {
	      error.EndOfStream => if (fbs.getWritten().len == 0) {
	          return null;
	      },
	      else => |e| return e,
	  };

	  var line = fbs.getWritten();
	  return line;
	}

	pub fn close(self: *Self) void {
		self.file.close();
		self.allocator.destroy(self.reader);
		self.allocator.destroy(self.buf);
	}
};
