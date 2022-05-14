;  TANDY WP-2 CONSOLE & PRINTER INTERFACE
;
; Last update:
;
; 220511 - Ported to Tandy WP-2
; 850511 - Saved BC' prior to CP/M calls
; 841010 - Saved IX & IY prior to CP/M calls
; 840909 - Converted all BIOS calls to BDOS calls for compatibility
;          with CP/M 3.0
;
;	Tandy WP-2 BIOS functions used by the console interface
;
BEEP	.EQU	0121H		;beep a buzzer
CHARGET	.EQU	0103H		;get one character (wait for input)
CHAROUT	.EQU	0118H		;output character to console
CHKCNCL	.EQU	0124H		;check that CNCL key is pressed now
CLS	.EQU	011EH		;clear screen
CURSON	.EQU	010FH		;set cursor on/off
CURSTYP	.EQU	0112H		;set cursor type
GETLOC	.EQU	010CH		;get cursor location
KILLBUF	.EQU	0106H		;kill key buffer
SETLOC	.EQU	0109H		;set cursor location
;
;	Memory locations accessed by the Tandy WP-2 console interface
;
CONSTAT	.EQU	8403H		;console status bits
VRAM	.EQU	9900H		;beginning of 3,840 bytes of VRAM
;
;	Console initialization.
;
CONINI:	LD	A,0		;select line cursor
	CALL	CURSTYP
	XOR	A		;switch cursor on
	CALL	CURSON
	JP	CLS		;clear screen
;
;	Emit a character
;
PEMIT:	.WORD	$+2		;(EMIT) orphan
	POP	DE		;(E)<--(S1)LB = CHR
	LD	A,E		;what are we printing?
	CP	ACR		;carriage return?
	JR	Z,PCR
	CP	LF		;line feed?
	JR	Z,PLF
	CP	FF		;form feed?
	JR	Z,PFF
	CP	BSIN		;backspace?
	JR	Z,PBS
	CP	BELL		;bell?
	JR	Z,PBELL
	CALL	GETLOC		;remember cursor in HL
	CALL	CHAROUT		;emit character
	LD	A,H		;was X<79?
	CP	79
	JR	C,PEMITE
	LD	A,L		;was Y<7?
	CP	7
	JR	C,PEMITE
	CALL	SCROLL
PEMITE:	JNEXT
;
;	Performs a carriage return and a line feed.
;
PCR:	CALL	GETLOC		;set cursor X=0
	LD	H,0
	CALL	SETLOC
;
;	Performs a line feed.
;
PLF:	CALL	GETLOC		;set cursor Y=Y+1
	INC	L
	LD	A,L
	CP	8
	JR	C,PLF1		;Y < 8
	CALL	SCROLL
	DEC	L
PLF1:	CALL	SETLOC
	JNEXT
;
;	Performs a form feed.
;
PFF:	PUSH	BC
	CALL	CLS
	POP	BC
	JNEXT
;
;	Performs a backspace.
;
PBS:	CALL	GETLOC		;get cursor position
	LD	D,H
	LD	E,L
	CALL	PBSB		;can we go backwards?
	RST	20h
	JR	Z,PBSE		;no
;
;	We can perform a backspace.
;
	CALL	SETLOC		;go back
	LD	A,ABL		;erase
	CALL	CHAROUT
	CALL	SETLOC		;go back once more
PBSE:	JNEXT
;
;	Given a cursor position in HL, return the previous cursor position in
;	HL if backspace were executed.
;
PBSB:	DEC	H
	LD	A,H
	CP	80h		;negative?
	RET	C
;
;	X<0
;
	LD	H,79		;set cursor X=79
	DEC	L		;set cursor Y=Y-1
	LD	A,L
	CP	80h		;negative?
	RET	C
;
;	Y<0 and X=79 
;
	LD	HL,0		;set cursor X=0 and Y=0
	RET
;
;	Rings the bell.
;
PBELL:	XOR	A		;0=low beep, 1=high beep
	CALL	BEEP
	JNEXT
;
;	Scrolls the display up one line of characters.
;
SCROLL:	PUSH	BC
	PUSH	HL
	LD	BC,7*480	;copy 7 lines
	LD	HL,VRAM+480	;from lines 1-7
	LD	DE,VRAM		;to lines 0-6
	LDIR
	LD	BC,480-1	;erase last line
	LD	HL,VRAM+(7*480)
	LD	DE,VRAM+(7*480)+1
	XOR	A
	LD	(HL),A
	LDIR
	POP	HL
	POP	BC
	RET
;
;	Read a key from the keyboard
;
PKEY:	PUSH	BC
PKEY1:	CALL	CHARGET		;wait for a key
	LD	L,H		;return key code
	LD	H,0
	POP	BC
	JHPUSH
;
;	Check whether the Esc/Cncl key is pressed
;
PQTER:	LD	HL,0		;assume not pressed
	CALL	CHKCNCL		;pressed now?
	JR	NC,PQTERE	;no, done
PQTER1:	CALL	CHKCNCL		;yes, wait until released
	JR	C,PQTER1
	CALL	KILLBUF		;clear keyboard buffer
	LD	HL,1		;signal it was pressed
PQTERE:	JHPUSH
