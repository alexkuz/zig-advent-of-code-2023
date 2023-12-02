const std = @import("std");

const Reader = std.io.Reader;
const BufferedReader = std.io.BufferedReader;
const File = std.fs.File;
const FileReader = Reader(File, File.ReadError, File.read);
const FileBufferedReader = BufferedReader(4096, FileReader);
const FixedStream = std.io.FixedBufferStream([]u8);

pub const LineReader = struct {
	file: std.fs.File,
	stream: Reader(*FileBufferedReader, FileReader.Error, FileBufferedReader.read),
	fbs: FixedStream,

	const Self = @This();

	pub fn open(path: []const u8, buf: *[1024]u8) !Self {
    var file = try std.fs.cwd().openFile(path, .{});

	  var reader = std.io.bufferedReader(file.reader());
	  var stream = reader.reader();
	  var fbs = std.io.fixedBufferStream(buf);

	  return .{
	  	.file = file,
	  	.fbs = fbs,
	  	.stream = stream
	  };
	}

	pub fn next(self: *Self) !?[]const u8 {
	  self.fbs.reset();
	  var writer = self.fbs.writer();
	  self.stream.streamUntilDelimiter(writer, '\n', 1024) catch |err| switch (err) {
	      error.EndOfStream => if (self.fbs.getWritten().len == 0) {
	          return null;
	      },
	      else => |e| return e,
	  };

	  var line = self.fbs.getWritten();
	  return line;
	}

	pub fn close(self: *Self) void {
		self.file.close();
	}
};