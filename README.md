# Mastermind
[Mastermind](https://en.wikipedia.org/wiki/Mastermind_(board_game)) board game as Zig learning project.

# Building and running

> Zig version: 0.13.0

To compile and run:
```sh
zig run main.zig
```

To build an executable:
```sh
zig build-exe main.zig --name mastermind
./mastermind
```

# How to play
Select a combination to guess by typing a sequence of digits (0-7) separated by spaces to select 4 colors.
After entering a guess, the number of correct colors guessed is reflected in white beads and the number of
correct colors in the correct positions is reflected in red beads, both right below the colors of the guess.

Guess the right combination of 4 distinct colors in 9 turns or less to win.
