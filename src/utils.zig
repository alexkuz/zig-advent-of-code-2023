const std = @import("std");

const Reader = std.io.Reader;
const BufferedReader = std.io.BufferedReader;
const File = std.fs.File;
const FileReader = Reader(File, File.ReadError, File.read);
const FileBufferedReader = BufferedReader(4096, FileReader);

pub const AppAllocator = std.heap.c_allocator;

pub const Result = struct {
	part1: i64,
	part2: i64,
	time: u64
};

pub const TestLineReader = struct {
	const Self = @This();
	lines: std.mem.SplitIterator(u8, .scalar),

	pub fn init(text: []const u8) !LineReader {
		return .{
			.test_reader = .{
				.lines = std.mem.splitScalar(u8, std.mem.trimRight(u8, text, "\n"), '\n')
			}
		};
	}

	pub fn next(self: *Self) !?[]const u8 {
		return self.lines.next();
	}
};

pub const FileLineReader = struct {
	file: std.fs.File,
	reader: *FileBufferedReader,
	stream: Reader(*FileBufferedReader, FileReader.Error, FileBufferedReader.read),
	allocator: std.mem.Allocator,
	buf: *[1024]u8,

	const Self = @This();

	pub fn open(path: []const u8, allocator: std.mem.Allocator) !LineReader {
    var file = try std.fs.cwd().openFile(path, .{});

    var reader = try allocator.create(FileBufferedReader);
	  reader.* = std.io.bufferedReader(file.reader());
	  const stream = reader.reader();

	  const buf = try allocator.create([1024]u8);

	  return .{
	  	.file_reader = .{
		  	.file = file,
		  	.stream = stream,
		  	.reader = reader,
		  	.allocator = allocator,
		  	.buf = buf,
		  }
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

	  const line = fbs.getWritten();
	  return line;
	}

	pub fn close(self: *Self) void {
		self.file.close();
		self.allocator.destroy(self.reader);
		self.allocator.destroy(self.buf);
	}
};

pub const LineReader = union(enum){
   test_reader: TestLineReader,
   file_reader: FileLineReader,

   pub fn next(self: *LineReader) !?[]const u8 {
      return switch (self.*) {
         inline else => |*case| case.next(),
      };
   }

   pub fn close(self: *LineReader) void {
      switch (self.*) {
      	.file_reader => |*case| case.close(),
         else => unreachable,
      }
   }
};

const Part = enum(u2) {
	Part1,
	Part2
};

pub fn testResult(comptime file: []const u8, dayFn: anytype, part: Part, expected: i64) !void {
  const allocator = std.testing.allocator;
  var reader = try TestLineReader.init(@embedFile(file));
  
  const result = try dayFn(allocator, &reader);

  switch(part) {
  	.Part1 => try std.testing.expectEqual(expected, result.part1),
  	.Part2 => try std.testing.expectEqual(expected, result.part2),
  }
}