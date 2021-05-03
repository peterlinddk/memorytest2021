# Memorytest 2021
A memorytester for Commodore 64.

I recently ran into a strange problem while repairing a Commodore 64 - it seemed to work okay(ish), but when I tried to run the diagnostic cartridge 
([C-64 Diagnostic Rev 586220](http://blog.worldofjani.com/?p=164)) it reported BAD on memory test2, and then crashed. However no ram chips were marked as being bad.
On the Dead Test (same link) no errors were reported.

I scrutinized the source-code (or rather, dissassembly) of the diagnostic, and it seems that there are a few errors when dealing with ram test 2. A minor one being
that it writes BAD next to ram test 1, but a more severe one, that if no ram chip has been registered as BAD by any of the previous ram-chips, it crashes. It seems
that the crash is because it tests the upper 32kB by copying code from $8000... down to $1000... and running it there - then it can write and read what it likes in
the upper memory. But if a BAD chip is encountered for the first time, it tries to execute code in the upper part of memory, that would usually be the rom of the cartridge,
but is disabled during the memorytest ... 

Nevermind, I wanted something to test the memory, and give me more detailed reports on what happens, so here it is: Memorytest 2021!

## Running
### Requirements

To run this on a Commodore 64, it must be able to boot and load from disk or tape.

If the machine can run Deadtest without any major issues, you can run this program - Deadtest tests the first 4kB, that this program requires to run!

You don't need to compile or assemble the code, you can use either the .d64 diskimage or the single .prg file directly from the releases folder.

### How to

Load the memorytest 2021 program as a normal basic-program, and run it.

The program will test addresses from $1000 to $FFFF by writing various bit-patterns into every single address, waiting for about a thousand clock-cycles, and reading
the values back to see if they are unchanged.

If an address doesn't provide the unchanged bit-pattern, it is written to the screen (however, there's only room for the first 84 errors, any further will not be shown,
but will be included in the final chip-status).

When the reading is done, the program displays either OK or BAD on each of the eight ram chips usually in a Commodore 64 - each chip corresponds to one of eight bits in
a byte, so if the test finds only errors with e.g. bit 2, it guesses that the chip responsible for that bit must be defective.

You can restart the test by pressing the fire-button on a joystick in either port (or indeed pressing the spacebar on a keyboard).

# Version history
v0.1 - first version for release


