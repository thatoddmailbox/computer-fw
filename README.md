# computer-fw
Firmware for the Soviet-era microcomputer I built. See [this repository](https://github.com/thatoddmailbox/computer) for more information.

## Usage
To assemble this firmware, you will need [z80asm](https://github.com/thatoddmailbox/z80asm) set up and working. Then, just run `z80asm --weird-mapping` in the folder with the firmware source code, and you will get two ROM files as output, `rom0.bin` and `rom1.bin`. These files can then be run using [the emulator](https://github.com/thatoddmailbox/computer-emu), or can be programmed onto a pair of ROM chips for use in an actual computer.