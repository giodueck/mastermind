// https://en.wikipedia.org/wiki/Mastermind_(board_game)

const std = @import("std");

const Color = enum(u8) { blue = 0, green, grey, orange, pink, red, white, yellow, end };
const ColorCodes = [_][]const u8{
    "\x1b[38;5;4m",
    "\x1b[38;5;2m",
    "\x1b[38;5;7m",
    "\x1b[38;5;202m",
    "\x1b[38;5;13m",
    "\x1b[38;5;1m",
    "\x1b[38;5;15m",
    "\x1b[38;5;3m",
    "\x1b[0m",
};

var secret: [4]Color = [_]Color{Color.end} ** 4;

const GuessResult = struct {
    colors: u8,
    positions: u8,
};

const MastermindError = error{
    InvalidInput,
    InvalidInputCount,
    InvalidColor,
};

fn printError(stdout: anytype, err: anyerror) !void {
    switch (err) {
        MastermindError.InvalidInput => {
            try stdout.writeAll("Invalid guess\n");
        },
        MastermindError.InvalidInputCount => {
            try stdout.writeAll("Invalid number of guesses\n");
        },
        MastermindError.InvalidColor => {
            try stdout.writeAll("Invalid color value\n");
        },
        else => {
            try stdout.print("Error: {}\n", .{err});
        },
    }
}

fn getRandomUnusedColor(rand: std.Random, slice: []Color) Color {
    // Trial and error generation but whatever, just quick and dirty until there are consequences
    outer: while (true) {
        const color: Color = @enumFromInt(rand.uintLessThanBiased(u8, 8));
        for (slice) |c| {
            if (color == c)
                continue :outer;
        }

        return color;
    }
    unreachable;
}

fn getPlayerGuess(stdin: anytype) ![4]Color {
    var guess_array: [4]Color = [_]Color{Color.end} ** 4;
    var buf = [_]u8{0} ** 100;

    const guess_string = try stdin.readUntilDelimiterOrEof(&buf, '\n');

    if (guess_string == null)
        return MastermindError.InvalidInput;

    var tokens_it = std.mem.tokenizeSequence(u8, guess_string.?, " ");
    var i: u8 = 0;
    while (tokens_it.next()) |tok| : (i += 1) {
        if (i >= 4) {
            return MastermindError.InvalidInputCount;
        }

        if (std.fmt.parseUnsigned(u8, tok, 10)) |value| {
            if (value >= @intFromEnum(Color.end))
                return MastermindError.InvalidColor;
            guess_array[i] = @enumFromInt(value);
        } else |_| {
            return MastermindError.InvalidInput;
        }
    }

    if (i != 4) {
        return MastermindError.InvalidInputCount;
    }

    return guess_array;
}

fn validateGuess(guess: []Color) !GuessResult {
    if (guess.len != secret.len)
        return MastermindError.InvalidInputCount;

    var ret_val: GuessResult = .{ .colors = 0, .positions = 0 };
    var marks = [_]bool{false} ** 4;

    for (guess, 0..) |color, i| {
        for (secret, 0..) |secret_color, j| {
            if (!marks[j] and color == secret_color) {
                ret_val.colors += 1;
                if (i == j) ret_val.positions += 1;
                marks[j] = true;
                break;
            }
        }
    }
    return ret_val;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    // Generate random sequence
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        secret[i] = getRandomUnusedColor(rand, secret[0..i]);
    }

    // ● is the char for the colored beads

    // Print help
    try stdout.print("Guess the secret code of 4 different colors in at most 9 guesses.\nYou get hints for correct colors in {s}●{s} white and correct positions in {s}●{s} red.\n", .{ ColorCodes[@intFromEnum(Color.white)], ColorCodes[@intFromEnum(Color.end)], ColorCodes[@intFromEnum(Color.red)], ColorCodes[@intFromEnum(Color.end)] });

    i = 0;
    while (i < 8) : (i += 1) {
        try stdout.print("{s}●{s} ", .{ ColorCodes[i], ColorCodes[@intFromEnum(Color.end)] });
    }
    try stdout.writeAll("\n");
    i = 0;
    while (i < 8) : (i += 1) {
        try stdout.print("{d} ", .{i});
    }
    try stdout.writeAll("\n\n");

    // Game loop
    var tries: u8 = 0;
    const max_tries: u8 = 9;

    gameloop: while (tries < max_tries) {
        // Get player guess
        const guess_return = getPlayerGuess(stdin);
        var guess_result: GuessResult = .{ .colors = 0, .positions = 0 };

        if (guess_return) |guess| {
            // Validate guess
            try stdout.print("{s}●{s} {s}●{s} {s}●{s} {s}●{s}\n", .{ ColorCodes[@intFromEnum(guess[0])], ColorCodes[@intFromEnum(Color.end)], ColorCodes[@intFromEnum(guess[1])], ColorCodes[@intFromEnum(Color.end)], ColorCodes[@intFromEnum(guess[2])], ColorCodes[@intFromEnum(Color.end)], ColorCodes[@intFromEnum(guess[3])], ColorCodes[@intFromEnum(Color.end)] });
            const result = validateGuess(@constCast(&guess));
            if (result) |value| {
                // Give feedback
                // try stdout.print("{d} {d}\n", .{ value.colors, value.positions });
                for (value.colors) |_| {
                    try stdout.print("{s}●{s} ", .{ ColorCodes[@intFromEnum(Color.white)], ColorCodes[@intFromEnum(Color.end)] });
                }
                try stdout.writeAll("\n");

                for (value.positions) |_| {
                    try stdout.print("{s}●{s} ", .{ ColorCodes[@intFromEnum(Color.red)], ColorCodes[@intFromEnum(Color.end)] });
                }
                try stdout.writeAll("\n");

                guess_result = value;
            } else |err| {
                try printError(stdout, err);
                unreachable; // guess should have been validated after getting it from stdin
            }
        } else |err| {
            try printError(stdout, err);
            continue :gameloop;
        }

        tries += 1;
        try stdout.writeAll("\n");

        if (guess_result.positions == 4) {
            try stdout.writeAll("You won!\n");
            return;
        }
    }

    try stdout.print("Game over\nSolution: {d} {d} {d} {d}\n", .{ @intFromEnum(secret[0]), @intFromEnum(secret[1]), @intFromEnum(secret[2]), @intFromEnum(secret[3]) });
}
