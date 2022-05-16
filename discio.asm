;  TANDY WP-2 DISC INTERFACE
;
; Last update:
;
; 220511 - ported to Tandy WP-2
; 201212 - added FILE
; 881228 - EXTEND's R/W address now initialized with blanks
; 860120 - EXTEND's R/W address now HERE, was Osborne video ram
; 850511 - saved BC' in 'BDOS'
; 850227 - saved index regs. in 'BDOS'
; 840812 - added EXTEND
; 840731 - installed BDOS calls
;
;	Tandy WP-2 BIOS functions used by the disc interface
;
OPEN	.EQU	0188h		;open a file
READ	.EQU	018Bh		;read a file
WRITE	.EQU	018Eh		;write a file
CLOSE	.EQU	0191h		;close a file
;
;	The File Control Block (FCB) used to communicate with the Tandy WP-2's
;	BIOS functions. Since the WP-2's BIOS does not appear to support random
;	access on most devices, we cannot combine multiple screens in a single
;	file, as the CP/M implementation did. Therefore we use one file per
;	screen, of exactly 1,024 bytes, named SCRN0000.FTH up to SCRNFFFF.FTH.
;
DEFFCB:	.BYTE	011h		;device (1=memory, 2=internal RAM disk, 3=IC RAM, 11h=drive A)
	.TEXT	"SCREEN??.FTH"	;filename, not zero-terminated; supports up to 64K screens
	.WORD	16*64		;one screen size
	.BLOCK	17		;reserved
;
;	FORTH variables & constants used in disc interface
;
	.BYTE	83H		;FCB (current FCB address)
	.TEXT	"FC"
	.BYTE	'B'+$80
	.WORD	PTSTO-5
FCB:	.WORD	DOCON,DEFFCB
;
	.BYTE	83H		;USE
	.TEXT	"US"
	.BYTE	'E'+$80
	.WORD	FCB-6
USE:	.WORD	DOVAR,0		;/ initialised by CLD
;
	.BYTE	84H		;PREV
	.TEXT	"PRE"
	.BYTE	'V'+$80
	.WORD	USE-6
PREV:	.WORD	DOVAR,0		;/ initialised by CLD
;
	.BYTE	85H		;#BUFF
	.TEXT	"#BUF"
	.BYTE	'F'+$80
	.WORD	PREV-07H
NOBUF:	.WORD	DOCON,NBUF
;
	.BYTE	8AH		;DISK-ERROR
	.TEXT	"DISK-ERRO"
	.BYTE	'R'+$80
	.WORD	NOBUF-08H
DSKERR:	.WORD	DOVAR,0
;
;	DISC INTERFACE HIGH LEVEL ROUTINES
;
	.BYTE	84H		;+BUF
	.TEXT	"+BU"
	.BYTE	'F'+$80
	.WORD	DSKERR-0DH
PBUF:	.WORD	DOCOL
	.WORD	LIT,CO
	.WORD	PLUS,DUP
	.WORD	LIMIT,EQUAL
	.WORD	ZBRAN
	.WORD	PBUF1-$
	.WORD	DROP,FIRST
PBUF1:	.WORD	DUP,PREV
	.WORD	AT,SUBB
	.WORD	SEMIS
;
	.BYTE	86H		;UPDATE
	.TEXT	"UPDAT"
	.BYTE	'E'+$80
	.WORD	PBUF-07H
UPDAT:	.WORD	DOCOL,PREV
	.WORD	AT,AT
	.WORD	LIT,8000H
	.WORD	ORR
	.WORD	PREV,AT
	.WORD	STORE,SEMIS
;
	.BYTE	8DH		;EMPTY-BUFFERS
	.TEXT	"EMPTY-BUFFER"
	.BYTE	'S'+$80
	.WORD	UPDAT-9
MTBUF:	.WORD	DOCOL,FIRST
	.WORD	LIMIT,OVER
	.WORD	SUBB,ERASEE
	.WORD	SEMIS
;
	.BYTE	83H		;DR0
	.TEXT	"DR"
	.BYTE	'0'+$80
	.WORD	MTBUF-10H
DRZER:	.WORD	DOCOL
	.WORD	LIT,0200h	;02h=internal RAM disk
	.WORD	OFSET,STORE
	.WORD	SEMIS
;
	.BYTE	83H		;DR1
	.TEXT	"DR"
	.BYTE	'1'+$80
	.WORD	DRZER-6
DRONE:	.WORD	DOCOL
	.WORD	LIT,01100h	;11h=floppy disk drive A
	.WORD	OFSET,STORE
	.WORD	SEMIS
;
	.BYTE	83H		;DR2
	.TEXT	"DR"
	.BYTE	'2'+$80
	.WORD	DRONE-6
DRTWO:	.WORD	DOCOL
	.WORD	LIT,0300h	;03h=IC RAM disk
	.WORD	OFSET,STORE
	.WORD	SEMIS
;
	.BYTE	86H		;BUFFER
	.TEXT	"BUFFE"
	.BYTE	'R'+$80
	.WORD	DRTWO-6
BUFFE:	.WORD	DOCOL,USE
	.WORD	AT,DUP
	.WORD	TOR
BUFF1:	.WORD	PBUF		; won't work if single buffer
	.WORD	ZBRAN
	.WORD	BUFF1-$
	.WORD	USE,STORE
	.WORD	RR,AT
	.WORD	ZLESS
	.WORD	ZBRAN
	.WORD	BUFF2-$
	.WORD	RR,TWOP
	.WORD	RR,AT
	.WORD	LIT,7FFFH
	.WORD	ANDD,ZERO
	.WORD	RSLW
BUFF2:	.WORD	RR,STORE
	.WORD	RR,PREV
	.WORD	STORE,FROMR
	.WORD	TWOP,SEMIS
;
	.BYTE	85H		;BLOCK
	.TEXT	"BLOC"
	.BYTE	'K'+$80
	.WORD	BUFFE-9
BLOCK:	.WORD	DOCOL,OFSET
	.WORD	AT,PLUS
	.WORD	TOR,PREV
	.WORD	AT,DUP
	.WORD	AT,RR
	.WORD	SUBB
	.WORD	DUP,PLUS
	.WORD	ZBRAN
	.WORD	BLOC1-$
BLOC2:	.WORD	PBUF,ZEQU
	.WORD	ZBRAN
	.WORD	BLOC3-$
	.WORD	DROP,RR
	.WORD	BUFFE,DUP
	.WORD	RR,ONE
	.WORD	RSLW
	.WORD	TWOMIN		;/
BLOC3:	.WORD	DUP,AT
	.WORD	RR,SUBB
	.WORD	DUP,PLUS
	.WORD	ZEQU
	.WORD	ZBRAN
	.WORD	BLOC2-$
	.WORD	DUP,PREV
	.WORD	STORE
BLOC1:	.WORD	FROMR,DROP
	.WORD	TWOP,SEMIS
;
; 	Tandy WP-2 helper word to call one of the above four BIOS functions.
;	Takes the values for the HL, DE, and A registers, as well as the address
;	of the function to call. Leaves either 0 (success) or 1 (error) on the
;	stack:
;
;	( HL DE A ADDRESS -- f )
;
	.BYTE	84H		;BIOS
	.TEXT	"BIO"
	.BYTE	'S'+$80
	.WORD	BLOCK-8
BIOS:	.WORD	$+2
	POP	HL		;pop address
	LD	(BIOS1+1),HL	;modify CALL 0 below
	POP	DE		;pop A
	LD	A,E
	POP	DE		;pop DE
	POP	HL		;pop HL
	PUSH	BC
BIOS1:	CALL	0		;self-modified address
	POP	BC
	LD	A,0		;carry flag was set on error
	ADC	A,0
	LD	L,A		;push 0=success, 1=error
	LD	H,0
	JHPUSH
;
;	Reads a block of data from a disc. For reasons mentioned above, each
;	screen equals one block of 1,024 bytes, which is stored in its own
;	file. The high byte of the block number (via OFFSET) contains the
;	drive to use.
;
	.BYTE	83H		;R/W
	.TEXT	"R/"
	.BYTE	'W'+$80
	.WORD	BIOS-7
RSLW:	.WORD	DOCOL
;
;	Update drive in FCB.
;
	.WORD	SWAP				;block number on top
	.WORD	LIT,256				;divide by 256
	.WORD	SLMOD				;leaving low and high byte
	.WORD	FCB,CSTOR			;store high byte as drive
	.WORD	SWAP				;and low byte as block number
;
;	Update filename in FCB.
;
	.WORD	SWAP
	.WORD	FCB,LIT,7,PLUS			;point to ?? in FCB
	.WORD	SWAP,ZERO			;convert SCR # to double
	.WORD	BASE,AT,TOR,HEX			;save BASE and go HEX
	.WORD	BDIGS,DIG,DIGS,EDIGS		;convert SCR # to 2 hex digits
	.WORD	FROMR,BASE,STORE		;restore BASE
	.WORD	ROT,SWAP,CMOVE
;
;	Read functionality.
;
	.WORD	ONE,EQUAL,ZBRAN			;check if f=1 (read)
	.WORD	RSLW3-$				;IF
	.WORD	ZERO,FCB,TWO,LIT,OPEN,BIOS	;open screen file
	.WORD	ZBRAN				;if success, read
	.WORD	RSLW1-$				;else fill screen
;
;	Read: file does not exist.
;
	.WORD	LIT,1024,BLANK			;clear the screen
	.WORD	BRAN
	.WORD	RSLW7-$
;
;	Read: file exists.
;
RSLW1:	.WORD	LIT,8,ZERO			;read 8 sectors
	.WORD	XDO
RSLW2:	.WORD	DUP,FCB,ZERO,LIT,READ,BIOS	;read a sector of 128 bytes
	.WORD	DUP,DSKERR,STORE		;update DISK-ERROR
	.WORD	LIT,8,QERR			;error out if necessary
	.WORD	LIT,128,PLUS			;advance data buffer
	.WORD	XLOOP				;next sector
	.WORD	RSLW2-$
	.WORD	DROP				;drop address
	.WORD	BRAN
	.WORD	RSLW6-$				;ELSE
;
;	Write functionality.
;
RSLW3:	.WORD	ZERO,FCB,ONE,LIT,OPEN,BIOS	;open existing screen file
	.WORD	ZBRAN
	.WORD	RSLW4-$
;
;	Write: file does not exist.
;
	.WORD	ZERO,FCB,ZERO,LIT,OPEN,BIOS	;create new screen file
	.WORD	DUP,DSKERR,STORE		;update DISK-ERROR
	.WORD	LIT,8,QERR			;error out if necessary
;
;	Write: file exists.
;
RSLW4:	.WORD	LIT,8,ZERO			;write 8 sectors
	.WORD	XDO
RSLW5:	.WORD	DUP,FCB,ZERO,LIT,WRITE,BIOS	;write a sector of 128 bytes
	.WORD	DUP,DSKERR,STORE		;update DISK-ERROR
	.WORD	LIT,8,QERR			;error out if necessary
	.WORD	LIT,128,PLUS			;advance data buffer
	.WORD	XLOOP				;next sector
	.WORD	RSLW5-$
	.WORD	DROP				;drop address
;
;	Close file.
;
RSLW6:	.WORD	FCB,ZERO,ZERO,LIT,CLOSE,BIOS	;ENDIF, close screen file
	.WORD	DUP,DSKERR,STORE		;update DISK-ERROR
	.WORD	LIT,8,QERR			;error out if necessary
RSLW7:	.WORD	SEMIS
;
	.BYTE	85H		;FLUSH
	.TEXT	"FLUS"
	.BYTE	'H'+$80
	.WORD	RSLW-6
FLUSH:	.WORD	DOCOL
	.WORD	NOBUF,ONEP
	.WORD	ZERO,XDO
FLUS1:	.WORD	ZERO,BUFFE
	.WORD	DROP
	.WORD	XLOOP
	.WORD	FLUS1-$
	.WORD	SEMIS
;
	.BYTE	84H			;LOAD
	.TEXT	"LOA"
	.BYTE	'D'+$80
	.WORD	FLUSH-8
LOAD:	.WORD	DOCOL,BLK
	.WORD	AT,TOR
	.WORD	INN,AT
	.WORD	TOR,ZERO
	.WORD	INN,STORE
	.WORD	BSCR,STAR
	.WORD	BLK,STORE		;BLK <-- SCR * B/SCR
	.WORD	INTER			;INTERPRET FROM OTHER SCREEN
	.WORD	FROMR,INN
	.WORD	STORE
	.WORD	FROMR,BLK
	.WORD	STORE,SEMIS
;
	.BYTE	0C3H			;-->
	.TEXT	"--"
	.BYTE	'>'+$80
	.WORD	LOAD-7
ARROW:	.WORD	DOCOL,QLOAD
	.WORD	ZERO
	.WORD	INN,STORE
	.WORD	BSCR,BLK
	.WORD	AT,OVER
	.WORD	MODD,SUBB
	.WORD	BLK,PSTOR
	.WORD	SEMIS
;
;
;
