# Tandy WP-2 fig-FORTH 1.3c Notes

Some notes relating to porting fig-FORTH to the Tandy WP-2.

## Documentation

[Archive.org](https://www.archive.org) contains the essential [Tandy WP-2 Portable Wordprocessor Service Manual](https://archive.org/download/Tandy_WP-2_Portable_Wordprocessor_Service_Manual_1989_Tandy/Tandy_WP-2_Portable_Wordprocessor_Service_Manual_1989_Tandy.pdf).

The relevant pages:

Start Page | Topic
-----------|---------------------------
26 (4-5)   | Memory Map
28 (4-7)   | Specific I/O Addresses
37 (4-16)  | RUN FILE format
39 (4-18)  | Specific Memory Addresses
121 (D-1)  | BIOS Calls

## LCD

The LCD has 480 x 64 monochrome pixels and is driven by an [OKI MSM6255](https://www.google.com/search?q=OKI+MSM6255) controller.

It can be used in both text and graphics modes, and even though the WP-2 is a
text-based device, it drives the LCD in graphics modes. In graphics mode each
pixel can be individually addressed, so the WP-2 is capable of monochrome
graphics!

- Text mode supports 8x8 character cells and a cursor 8 pixels wide. This means using
text mode with 480 pixels across would give a resolution of 480 / 8 = 60 text columns.

- Driving the display in graphics mode allows the WP-2 to draw characters 6x8 pixels in
size, meaning 480 pixels across give a resolution of 480 / 6 = 80 text columns, at the
cost of more code complexity:

    Since 3 bytes in RAM make up 3 x 8 = 24 horizontal pixels, these impact 24 / 6 = 4
    characters. That means when writing a single character, the BIOS (see below) has
    to figure out which bits of which byte in memory it needs to change and which bits
    to keep, since they are of adjacent characters.

If you imagine four adjacent 'h' characters starting in the home position of the
LCD:

    # . . . . . # . . . . . # . . . . . # . . . . .
    # . . . . . # . . . . . # . . . . . # . . . . .
    # . # # . . # . # # . . # . # # . . # . # # . .
    # # . . # . # # . . # . # # . . # . # # . . # .
    # . . . # . # . . . # . # . . . # . # . . . # .
    # . . . # . # . . . # . # . . . # . # . . . # .
    # . . . # . # . . . # . # . . . # . # . . . # .
    . . . . . . . . . . . . . . . . . . . . . . . .

If we write the byte FFh to its corresponding RAM address (9900h as configured by the
BIOS), we end up with:

    # # # # # # # # . . . . # . . . . . # . . . . .
    # . . . . . # . . . . . # . . . . . # . . . . .
    # . # # . . # . # # . . # . # # . . # . # # . .
    # # . . # . # # . . # . # # . . # . # # . . # .
    # . . . # . # . . . # . # . . . # . # . . . # .
    # . . . # . # . . . # . # . . . # . # . . . # .
    # . . . # . # . . . # . # . . . # . # . . . # .
    . . . . . . . . . . . . . . . . . . . . . . . .

If we had written the byte FFh to the second RAM address (9901h) instead, we would have
ended up with:

    # . . . . . # . # # # # # # # # . . # . . . . .
    # . . . . . # . . . . . # . . . . . # . . . . .
    # . # # . . # . # # . . # . # # . . # . # # . .
    # # . . # . # # . . # . # # . . # . # # . . # .
    # . . . # . # . . . # . # . . . # . # . . . # .
    # . . . # . # . . . # . # . . . # . # . . . # .
    # . . . # . # . . . # . # . . . # . # . . . # .
    . . . . . . . . . . . . . . . . . . . . . . . .

And had we written it to the third RAM address (9902h) instead, we would have gotten:

    # . . . . . # . . . . . # . . . # # # # # # # #
    # . . . . . # . . . . . # . . . . . # . . . . .
    # . # # . . # . # # . . # . # # . . # . # # . .
    # # . . # . # # . . # . # # . . # . # # . . # .
    # . . . # . # . . . # . # . . . # . # . . . # .
    # . . . # . # . . . # . # . . . # . # . . . # .
    # . . . # . # . . . # . # . . . # . # . . . # .
    . . . . . . . . . . . . . . . . . . . . . . . .

The LCD supports a hardware cursor 8 pixels wide, but obviously the WP-2 does not use
that but instead implements a software cursor 6 pixels wide.

The 480 x 64 monochrome pixels need 30,720 bits or 3,840 bytes (3.75 Kb) of RAM.
The LCD controller is configured by the BIOS to find it at 9900h - A7FFh.

## ROM Paging

The WP-2 has 256 Kb of ROM built-in, of which the lower 16 Kb is permanently
mapped to memory address space 0000h - 3FFFh and is called the BIOS (Basic
Input/Output System).

- This BIOS and takes care of booting the machine, initializing the hardware,
dealing with interrupts, offering various routines to interface with the hardware,
and dropping you into the Wordprocessor application.

- The remaining 256 - 16 = 240 Kb is divided into multiple pages of 16 Kb, one of
which can be paged into the memory address space 4000h - 7FFFh at a time.

    I have not looked into these pages, but I believe most of it is made up of
    the large dictionary of some 200,000 words.

Furthermore, if you insert a ROM IC card in the expansion slot on the left of
the machine, it too can contain a ROM of up to 256 Kb whose 16 Kb pages can be
mapped into the 4000h - 7FFFh memory address space.

Paging ROM (and RAM, see below) in and out happens by writing to I/O port 51h.

## RAM Paging

The WP-2 has 32 Kb of SRAM built-in, but also supports RAM present on:

1. An optional 32 Kb or 128 Kb SRAM chip which can be placed in the empty socket
  on the motherboard.

2. A 32 Kb RAM IC card in the expansion slot on the left.

Both these additional RAM sources cannot be used to expand the "working memory"
of the WP-2 -- they can only be used as RAM drives for storage.

The built-in 32 Kb of SRAM is _permanently_ mapped to memory address space
8000h - FFFFh, yet somehow the additional RAM (drive) memory can be "mapped in and
out" by writing to port 51h. How then can this additional RAM be accessed?

The Service Manual does actually describe how this happens, but rather as short
sentences and since I had never seen this mechanism used before, I completely
missed it at first. The manual explains (page 25, 4-5, IV-4. Memory Map):

> Expansion RAM is mapped on the I/O address.

When you page a RAM (drive) page in, its 32 Kb page is not mapped into the
_memory_ address space, but rather in the _I/O_ address space.

For example, to read the first byte of a paged-in RAM (disk) page, you could
issue:

    LD    BC,8000h
    IN    A,(C)         ; this reads from I/O port BC, not just C

The addresses these RAM (drive) pages map to, fall in the same numerical range
as where the built-in 32 Kb SRAM is placed, i.e., from 8000h - FFFFh.

## Memory Allocation

The WP-2 treats its 32 Kb internal RAM as numbered blocks of 32 bytes, starting
at address 8000h for block number zero. This gives 32 Kb / 32 = 1,024 or 400h blocks:

       +-------+-------+-------+----/----+--------+--------+
       |   0   |   1   |   2   |   ...   |  3FEh  |  3FFh  |   block
       +-------+-------+-------+----/----+--------+--------+
    8000h   8020h   8040h   8060h     FFC0h    FFE0h    FFFFh  memory address

The WP-2 maintains its memory allocation administration by means of a doubly-linked
list. Each node in the list is also 32 bytes in size for convenience, and contains
three things:

Offset | Bytes | Meaning
-------|-------|--------
0      | 1     | Status of the allocated node (free, used, etc.).
1      | 2     | Block number of next node in the list.
3      | 2     | Block number of previous node in the list.
5      | 27    | Unused.

Or graphically:

    +---+---+---+---+---+---+---+--/--+---+---+
    |St.|  Next |  Prev |       Unused        |
    +---+---+---+---+---+---+---+--/--+---+---+
    0   1   2   3   4   5                31  32  offset

A node's status is represented by the ASCII code of a character, which at the
look of it have a bearing on English words. The following are used by the BIOS:

Status | Meaning
-------|--------
`S`    | Stop. End of the list. Next block always zero.
`F`    | Free. This block is available to be malloc'ed.
`u`    | Used. This block can be free'd.
`U`    | Unusable? Empty block (0 bytes)?
`P`    | Protected? First block only can be `P`?

The space that is assigned to a node follows the node immediately, as a number of
32-byte blocks. That space in turn is followed by the next node in the list, and
so on, until an `S` node is encountered.

For example:

          80h    81h    82h    83h    84h    85h    86h    87h    88h    89h     block number
       +------+------+------+------+------+------+------+------+------+------+
       | node |      96 bytes      | node |  32  | node |   64 bytes  | node |
       +------+------+------+------+------+------+------+------+------+------+
    9000h  9020h  9040h  9060h  9080h  90A0h  90B0h  90C0h  90D0h  90E0h  90F0h  memory address

In the example above, if the first node resides at memory address 9000h or block
80h, and it represents 96 bytes of memory, then it will be followed by a gap of
96 bytes (3 blocks of 32 bytes). The next node is then found at memory address
9080h or block 84h.

The first node will have block 84h as the next node's block number in its administration,
and the second node will have block 80h as the previous node's block number in its
administration, and so on:

          Next   Previous
    +---+---+---+---+---+---+---+--/--+---+---+
    |St.|  84h  |  00h  |       Unused        |   node  at 80h
    +---+---+---+---+---+---+---+--/--+---+---+
    |                                         |   space at 81h
    +                                         +
    |                96 bytes                 |   space at 82h
    +                                         +
    |                                         |   space at 83h
    +---+---+---+---+---+---+---+--/--+---+---+
    |St.|  86h  |  80h  |                     |   node  at 84h
    +---+---+---+---+---+---+---+--/--+---+---+
    |                32 bytes                 |   space at 85h
    +---+---+---+---+---+---+---+--/--+---+---+
    |St.|  89h  |  84h  |                     |   node  at 86h
    +---+---+---+---+---+---+---+--/--+---+---+
    |                                         |   space at 87h
    +                64 bytes                 +
    |                                         |   space at 88h
    +---+---+---+---+---+---+---+--/--+---+---+
    | S |  00h  |  86h  |                     |   node  at 89h
    +---+---+---+---+---+---+---+--/--+---+---+

Assuming the node at 80h is the very first node, it will have zero as the
block number of its previous node. And assuming the node at 89h is the end
node, it will have status `S` and zero as the block number of its next node.

When you allocate memory via the `MALLOC` BIOS call, on exit HL will contain
the address of the first (allocated) block after the relevant node, and DE
will contain the size of this allocated space in block units. E.g., when you
allocate 64 bytes, DE will equal two on return.

Memory address 88DDh contains the block number of the head of the list. After
an application (such as fig-FORTH) has run, the BIOS sets the head to block
160h, which is RAM address AC00h or the application load address.

### Impact on fig-FORTH

Understanding the memory allocation was important because I wanted fig-FORTH
to play nicely with the BIOS. I.e., you should be able to return gracefully
to the system without needing a reboot.

When fig-FORTH is loaded by the BIOS, starting at address AC00h, and ending
about 7 Kb (the size of the `figforth.ex` binary) later, the BIOS immediately
places its memory administration head node there!

Also, at the top of RAM there seems to be some space used for the resident
document or a RAM disk on the internal 32 Kb SRAM (not sure):

    +-----------+ FFFFh
    | RAM disk? |
    +-----------+
    |           |
    /           /
    |           |
    +-----------+
    | head node |
    +-----------+
    |           |
    | fig-FORTH |
    |  binary   |
    +-----------+ AC00h
    |           |
    /           /
    |           |
    +-----------+ 0000h

This means I cannot simply assume all subsequent RAM is available to me: the
malloc head node sits squarely in the middle.

There are two approaches to deal with this, both of which I implemented:

1. Let the head node sit there and work around it.

    This means we have to set `FENCE` and `DP` right above the head node. Also,
    since the sole purpose of the `TASK` word is that it can be forgotten via
    `FORGET`, we have to place that above `FENCE`. That means we cannot
    _statically_ define `TASK` in the assembly listing, but the cold start
    routine has to _dynamically_ create `TASK` as its final act.

    The memory map would then look like this: 

        +-----------+ FFFFh
        | RAM disk? |
        +-----------+ LIMIT
        | allocated |
        |    to     |
        | fig-FORTH | TASK, DP
        +-----------+ FENCE
        | head node |
        +-----------+
        |           |
        | fig-FORTH |
        |  binary   |
        +-----------+ AC00h
        |           |
        /           /
        |           |
        +-----------+ 0000h

    This works fine, but the 32-byte head node we have to step around is
    annoying.

2. Move the head node.

    This is the approach I went with in the end. After all memory has been
    allocated, I actively move the head node to the end of the memory allocated
    to me, and claim the 32 bytes it occupied for myself. I also update the
    head block number, just for consistency. When terminating, I revert this
    process. This way we end up with a nice, contiguous memory space, and we
    can define `TASK` in the assembly code as usual:

        +-----------+ FFFFh
        | RAM disk? |
        +-----------+
        | head node |
        +-----------+ LIMIT
        | allocated |
        |    to     |
        | fig-FORTH |
        +-----------+ DP
        |           | TASK, FENCE
        | fig-FORTH |
        |  binary   |
        +-----------+ AC00h
        |           |
        /           /
        |           |
        +-----------+ 0000h

## ROM Version

My Tandy WP-2 reports the following ROM versions:

    Copyright 1989 CITIZEN WATCH CO.,LTD.
    Copyright 1989 Something Good Inc. V1.54
    Copyright 1989 Microlytics,UFO,Xerox V4.7

Online I have also seen photos of WP-2's with the second line reading:

    Copyright 1989 Something Good Inc. V1.62

It would be interesting to verify whether the bugs listed below are fixed in that version.

## Bugs

While porting I encountered two bugs in the BIOS:

1. When loading a RUN FILE, it attemps to round the file size up to the next
   multiple of 32 bytes. To determine whether it is a multiple, it correctly
   looks at the lower byte of the size only (anything `xxx00000` is a multiple).
   If so, it sets the lower bits to zero and adds 32.
   
   The bug occurs because it does not deal with the carry. I had a low byte of
   E1h once, which rounds up to 100h. In that case it should have incremented
   the high byte as well, but it does not do that, so my E1h got turned into 00h
   and the file size was truncated by E1h = 225 bytes.

   Relevant code starting at address 1FE6h in the BIOS:

        1fe6 5e              LD         E,(HL)              ; low byte of size
        1fe7 7b              LD         A,E
        1fe8 e6 1f           AND        00011111b           ; multiple of 32 bytes?
        1fea 28 06           JR         Z,is_multiple       ; yes, no rounding up necessary
        1fec 7b              LD         A,E
        1fed e6 e0           AND        11100000b           ; round up to next multiple
        1fef c6 20           ADD        A,32                ; may result in carry
        1ff1 5f              LD         E,A
                      is_multiple
        1ff2 23              INC        HL
        1ff3 56              LD         D,(HL)              ; high byte, but no carry correction
        1ff4 ed 53 6b 8a     LD         (app_size),DE       ; store it

   This is important because the BIOS places its memory administration immediately
   after the loaded program. If it gets the program size wrong, it will overwrite
   part of the end of the program with its memory administration.

2. The BIOS `PUTCHAR` routine at 1A3h supports escape sequences. One such
   sequence is `ESC` + `K`, which is supposed to erase from the cursor
   position to the end of the line.

   The cursor position is stored as two 8-bit values in subsequent memory
   addresses at 8357h (Y position) and 8358h (X position). These are usually
   loaded by a single instruction into register HL.
   
   As the Z80 is a little-endian processor, this means the low byte (L) is
   loaded from the lower address (8357h) and thus will contain the Y position,
   wherease the high byte (H) is loaded from the higher address (8358h) and
   will contain the X position.

   You can imagine this is easy to get wrong, and that is exactly what the BIOS
   does when implemeting this escape code. It wants to retrieve the cursor's
   X position and subtract it from 80 (the number of columns of the display) to
   get the number of columns it should clear. E.g., if the cursor is at X = 10,
   then it has 80 - 10 = 70 columns left to clear.

   Except the code starting at 2356h subtracts the Y coordinate from 80:

        2356 2a 57 83        LD         HL,(cursor_xy_position)     ; H=X, L=Y position
        2359 e5              PUSH       HL
        235a 3e 50           LD         A,80                        ; number of columns to
        235c 95              SUB        L                           ; erase is 80 - Y ?
                         loop 
        235d f5              PUSH       AF
        235e 3e 20           LD         A,' '                       ; output a space
        2360 cd eb 05        CALL       bios_char_out
        2363 f1              POP        AF
        2364 3d              DEC        A
        2365 28 02           JR         Z,done                      ; btw, why not simply
        2367 18 f4           JR         loop                        ; JR NZ,done ?
                         done 
        2369 e1              POP        HL
        236a 22 57 83        LD         (cursor_xy_position),HL
        236d c9              RET

    I noticed this because I had used this escape code when implementing
    scrolling the screen up, and the rightmost few characters on the last
    line were never erased.
