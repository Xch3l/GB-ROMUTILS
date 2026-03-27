# ROM Utils

A (not so) simple app that runs on a GameBoy. Useful to do some things such as backing up a game's ROM/SRAM via link cable, testing its save RAM and/or mess with its RTC. Or you can send/receive IR* signals with a GameBoy Color.

This software has been tested with a Gameboy Color and a Gameboy Advance. In GBA mode, the app has a safeguard that'll restrict itself to active spinwaiting from HRAM as the GBA will switch modes between 3.3v and 5v bus driving voltages (due to the internal switch in the cart. slot). This disconnects WRAM (where this thing is running) and can cause the app to crash.

\* Playing with IR is still a work in progress, until I figure a consistent way to transmit data without having to stick my eyes into the infrared diode (figuratively).

## Menu structure

Following is a wall of text explaining the handful of options available. Press &#x24B6; to select an option or &larr;/&rarr; to select a value where applicable. Due to emulation limitations and/or hardware availability (stuff I don't have), striked out text means `not implemented (yet) but roughly what it should do`.

- View Header: Displays a parsed view of the data at `$0134` to `$014F` (ROM header). Press &#x24B6;/&#x24B7; to return.
- Backup ROM: Dumps the entire contents via Link Cable. No special data format other than "looks like SPI without `/CS` line".
- Backup SRAM: Dumps the entire contents of game SRAM (if available) via Link Cable. Same "data format" as **Dump ROM**.
- ~~Restore SRAM: Listens for a Link Cable transmisison and puts the data into SRAM.~~
- Cart Options: Misc. utilities related to the hardware inside the cartridge, such as RTC, Rumble, SRAM Testing and ROM Hashing.
	- View RTC: Shows the current time and count of days. Also allows to set the time and flags.
	- Test SRAM: Test the SRAM chip for defects or broken soldering. Will overwrite data!
	- ~~Test Rumble: Tests the vibration motor~~
	- ~~Hash ROM: Performs a CRC32 of the game data~~
- Test IR: see following section

## **Test IR** menu (available only in GBC)

In this menu you can play with the (criminally neglected) infrared feature!

- Receive: Plays a sound everytime the IR diode senses light.
- Transmit: Data to send via infrared port.
- Timer: Timer reload value.
- Divider: Sets Timer M-Cycle division.
- Toggle: Toggles the state of the IR diode, leaving it ON or OFF while in this menu.

For now there is no defined protocol but an attempt to make it like this:

```
      _______         ______ ______ ______ ______ ______ ______ ______ ______ _______
...__/   1   \___0___/__b7__X__b6__X__b5__X__b4__X__b3__X__b2__X__b1__X__b0__X   1   \__...
     | Start bits    | Data byte (MSB first)                                 | Stop bit
```

A `1` bit will look like this:
```
________
        \______
```

and a `0` bit will be:
```
       ________
______/
```

## Warning

Contrary to safety guidelines, this app expects you to unplug and insert a different game cartridge once on the main menu for it to do its work (except IR). Such actions may damage your system, cartridges, flashcarts, self, earth or what have you; I assume no responsibility in such unfortunate events. From my own experience with a sketchy makeshift "flashcart", so far I've had no issues besides games with MBCs triggering a reset upon insertion so [YMMV](https://www.merriam-webster.com/slang/ymmv).
