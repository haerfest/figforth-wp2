# Tandy WP-2 fig-FORTH 1.3c

This is a port of [Z80 fig-FORTH 1.3c](https://github.com/dimitrit/figforth) (SHA 3c4e672) to the
[Tandy WP-2 Portable Wordprocessor](http://tandy.wiki/WP-2).

## Installation

What you will need to run this:

1. A Tandy WP-2.
2. A modern computer with a serial port.
3. A null-modem cable to connect the two.
4. A [Tandy Portable Disk Drive server](http://tandy.wiki/TPDD_server) to serve the file.

Then:

1. On your modern computer, start your TPDD server of choice, making sure it serves the directory with the `figforth.ex` file.
2. On the WP-2, from inside the Wordprocessor application, start the `FILES` application (`F2` + `=`).
3. Use the arrow keys left/right to highlight `DISKETTE` and press `Enter`.
4. Use the arrow keys up/down to highlight `figforth.ex` and press `F2` + `7` (RUN).

After a few seconds of transferring the binary over, the Forth prompt should appear and you can
program away on your WP-2:

![Forth Prompt](img/forth-wp2.jpg)

(Yes, that is a Forth version of the [BASIC Benchmark](https://docs.google.com/spreadsheets/d/1bfWSR2Ngy1RPedS6j-M607eeAhsd40-nhAfswILzzS8/edit?usp=sharing) of [Noel's Retro Lab](https://www.youtube.com/c/NoelsRetroLab/).)

## Tips

You can go back to the `FILES` application by entering `BYE`.

Highly recommended is to install a [128 Kb SRAM memory upgrade](http://tandy.wiki/WP-2#RAM_Disk)
in the WP-2 to act as a RAM drive. You can then copy the executable to it and run it from there
while on the go :)

## Screen Output

Because the WP-2's LCD only shows eight lines of output, I took a hint from the Commodore 64.
You can press the following keys while lines are being printed to the screen:

Key     | Effect
--------|----------------------------------------------------
`Ctrl`  | Pauses briefly before printing the next line.
`Shift` | Pauses printing the next line until released again.

## Storage

Each screen of 1,024 bytes is stored in a single file named `SCREEN??.FTH`, where the `??` is the zero-padded screen number in hexadecimal. This allows for 256 screens or 256 Kb storage per drive.

When loading or saving screens, you can switch drives with these words:

Word  | Drive
------|----------------------------------------------------
`DR0` | Internal RAM drive (32 Kb or 128 Kb socketed chip).
`DR1` | Floppy disk / drive A / TPDD.
`DR2` | IC RAM card in expansion slot.

## Notes

See [`README-WP2.md`](README-WP2.md) for notes regarding porting fig-FORTH to the WP-2.

_(Original README contents follow.)_

# Z80 fig-FORTH 1.3

> <h2><i>figForth Refuses to Die<sup>1</sup></i></h2>   
<br/>    

A fig-FORTH<sup>2</sup> implementation for the Z80 that can be built using TASM<sup>3</sup>:
   
```
$ tasm -80 -b figforth.asm forth.com forth.lst
```

Alternatively, non-Windows users can use the `uz80as`<sup>4</sup> Z80 compiler.

The resulting `forth.com` executable can be run in CP/M. For example<sup>5</sup>:
```
A>FORTH ↵

Z80 fig-FORTH 1.3c
: CUBE ( N -> N.  CUBE A NUMBER ) ↵
   DUP DUP  ( NOW THERE ARE THREE COPIES ) ↵
   * * ↵
; ↵ ok
5 CUBE . 125 ↵ ok
-28 CUBE . ↵ -21952 ok
HEX 17 CUBE BINARY . DECIMAL ↵ 10111110000111 ok
BYE ↵
A>
```

## Custom Words
This fig-FORTH implementation includes the following custom words<sup>6</sup>:

`(OF)`&nbsp;&nbsp;&nbsp;&nbsp;` n1 n2 --- n1 ` _(if no match)_   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;` n1 n2 --- ` _(if there is a match)_  
<ul>
The run-time procedure compiled by `OF`. See the description of the 
run-time behaviour of `OF`.
</ul>

`CASE`&nbsp;&nbsp;&nbsp;&nbsp;` --- addr n ` _(compiling)_   
<ul>
Used in a colon definition in the form: `CASE...OF...ENDOF...ENDCASE`.
Note that `OF ... ENDOF` pairs may be repeated as necessary.

At compile time `CASE` saves the current value of `CSP` and resets
it to the current position of the stack. This information is used
by `ENDCASE` to resolve forward references left on the stack by any
`ENDOF`s which precede it. `n` is left for compiler error checking.

`CASE` has no run-time effects.
</ul>

`ENDCASE`&nbsp;&nbsp;&nbsp;&nbsp;` addr1...addrn n --- ` _(compiling)_   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;` n --- ` _(if no match)_   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;` --- ` _(if a match was found)_   
<ul>
Used in a colon definition in the form: `CASE...OF...ENDOF...ENDCASE`.
Note that `OF ... ENDOF` pairs may be repeated as necessary.

At run-time, `ENDCASE` drops the select value if it does not equal any
case values.  `ENDCASE` then serves as the destination of forward
branches from all previous `ENDOF`s.

At compile-time. `ENDCASE` compiles a `DROP` then computes forward 
branch offsets until all addresses left by previous `ENDOF`s have been
resolved. Finally, the value of `CSP` saved by `CASE` is restored. `n`
is used for error checking.
</ul>

`ENDOF`&nbsp;&nbsp;&nbsp;&nbsp;` addr1 n1 --- addr2  n2 ` _(compiling)_   
<ul>
Used in a colon definition in the form: `CASE...OF...ENDOF...ENDCASE`.
Note that `OF ... ENDOF` pairs may be repeated as necessary.

At run-time, `ENDOF` transfers control to the code following the next
`ENDCASE` provided there was a match at the last `OF`. If the was no
match at the last `OF`, `ENDOF` is the location to which execution
will branch.

At compile-time `ENDOF` emplaces `BRANCH` reserving a branch offset,
leaves the address `addr2` and `n2` for error checking. `ENDOF` also
resolves the pending forward branch from `OF` by calculating the offset
from `addr1` to `HERE` and storing it at `addr1`.
</ul>

`FILE`&nbsp;&nbsp;&nbsp;&nbsp;` cccc `   
<ul>
Close the current .FTH file, and opens the given file. Note that a 
file can be loaded automatically on startup by specifying its name on 
the command line, e.g. `FORTH SCREENS.FTH`. Startup will be aborted 
with a `No File` error message if the file cannot be opened.
</ul>

`FTYPE`&nbsp;&nbsp;&nbsp;&nbsp;` --- addr `   
<ul>
A constant containing the three character file type used by `FILE`.   
Defaults to **.FTH**.
</ul>

`OF`&nbsp;&nbsp;&nbsp;&nbsp;` --- addr  n ` _(compiling)_   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;` n1 n2 --- n1 ` _(if no match)_   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;` n1 n2 --- ` _(if there is a match)_   
<ul>
Used in a colon definition in the form: `CASE...OF...ENDOF...ENDCASE`.
Note that `OF ... ENDOF` pairs may be repeated as necessary.

At run-time, `OF` checks `n1` and `n2` for equality. If equal, `n1` and `n2`
are both dropped from the stack, and execution continues to the next `ENDOF`.
If not equal, only `n2` is dropped, and execution jumps to whatever follows
the next `ENDOF`.
</ul>

## RomWBW extensions
Support for RomWBW HBIOS features<sup>7</sup> is included when fig-FORTH 
is built with the `-DROMWBW` flag:

`.B`&nbsp;&nbsp;&nbsp;&nbsp;` n -- `   
<ul>
Print a BCD value, converted to decimal. No following blank is printed.
</ul>

`AT`&nbsp;&nbsp;&nbsp;&nbsp;` col row --- `   
<ul>
Position the text cursor at the given position. Both column and 
row positions are zero indexed, thus `0 0 AT` will move the cursor
to the top left. Note that `AT` does *not* update `OUT`.
</ul>

`CLS`&nbsp;&nbsp;&nbsp;&nbsp;` --- `   
<ul>
Clear VDU screen.
</ul>

`KEY?`&nbsp;&nbsp;&nbsp;&nbsp;` --- c t ¦ f `   
<ul>
Check if a key has been pressed. Returns false if no key has been
pressed. Returns true and the key's ascii code if a key has been
pressed. 
</ul>

`STIME`&nbsp;&nbsp;&nbsp;&nbsp;` addr --- `   
<ul>
Set the RTC time. addr is the address of the 6 byte date/time buffer, 
YMDHMS. Each byte is BCD encoded.
</ul>

`TIME`&nbsp;&nbsp;&nbsp;&nbsp;` --- addr `   
<ul>
Get the RTC time and leave the address of the 6 byte date/time buffer, 
YMDHMS. Each byte is BCD encoded.
</ul>

## fig-FORTH Editor
The fig-FORTH EDITOR<sup>8</sup> is included in the `SCREENS.FTH` file:
```
FILE SCREENS ↵ ok
7 12 INDEX ↵

  7 ( fig-FORTH EDITOR V2.0 SCR 1 of 6)
  8 ( fig-FORTH EDITOR V2.0 SCR 2 of 6)
  9 ( fig-FORTH EDITOR V2.0 SCR 3 of 6)
 10 ( fig-FORTH EDITOR V2.0 SCR 4 of 6)
 11 ( fig-FORTH EDITOR V2.0 SCR 5 of 6)
 12 ( fig-FORTH EDITOR V2.0 SCR 6 of 6)ok
7 LOAD ↵ 2DROP MSG # 4  R MSG # 4  I MSG # 4  ok
EDITOR ↵ ok
1 CLEAR ↵ ok
0 P ( EAT MORE PIES! ) ↵ ok
1 LIST ↵
SCR # 1 
  0 ( EAT MORE PIES! )
  1 
  2 
  3 
 ... 
 14 
 15 
ok
FLUSH ↵ ok
```

## fig-FORTH 8080/Z80 Assembler
The fig-FORTH assembler enables the creation of both full and defining 
words using assembly language. 

The assembler is invoked using `CODE`, which creates a dictionary entry 
with given name and then assembles the mnemonics following. The mnemonics
are based on the 8080 instruction set with Z80 specific extensions. 
The assembly code must end with `PCIX` to ensure control is returned to Forth. 

Note that Forth postfix notation applies between opcodes and operands.

```
CODE FOO  ( n1 n2 -- n3 as sum of n1 + n2 )
  H POP   ( get first number from stack   )
  D POP   ( get second number from stack  )
  D DAD   ( add hl and de, result in hl   )
  H PUSH  ( push result to top of stack   )
  PCIX    ( jump to NEXT                  )
C;  ( end of definition, return to FORTH  )
```

The following rules apply when creating words using the assembler:

1. The `BC` register pair must be preserved across words.
1. Avoid use of the Z80 alternative register set.
1. Do NOT use the `IY` or `IX` registers, which are used by fig-FORTH to
keep track of the inner interpreter routine.
1. Definitions must end with `PCIX` (cf. `JNEXT` in `figforth.asm`) or 
`PCIY` (cf. `JHPUSH`).

Additionally, the assembler performs minimal checks which means that it is 
easy to create illegal instructions, resulting in systems hangs or crashes.

## References
1. C. H. Ting, _Systems Guide to figForth_, 3rd Edn (San Mateo, CA: Offete Enterprises, 2013), p. vi
2. William Ragsdale, _'fig-FORTH INSTALLATION MANUAL'_ (San Carlos, CA: FORTH INTEREST GROUP, 1980)
3. Thomas Anderson, _The Telemark Assembler (TASM) User's Manual (1998)_, Vintagecomputer <http://www.vintagecomputer.net/software/TASM/TASMMAN.HTM> [Accessed 14 December 2020]
4. Jorge Giner, _uz80as - Micro Z80 Assembler_, Github <https://github.com/jorgicor/uz80as> [Accessed 19 January 2021]
5. John James, _‘What Is Forth? A Tutorial Introduction’_, in BYTE, 5.8 (1980), 100–26
6. Charles Eaker, _'JUST IN CASE'_  in FORTH DIMENSIONS, II/3 (1980), 37-40
7. Wayne Warthen, _RomWBW Architecture_, (RetroBrew Computers Group, 2020)   
8. Bill Stoddart, _'EDITOR USER MANUAL'_, (London, UK: FIG United Kingdom, ND)
