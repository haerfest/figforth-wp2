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
CHKCNCL	.EQU	0124H		;check that CNCL key is pressed now
CLS	.EQU	011EH		;clear screen
CURSON	.EQU	010FH		;set cursor on/off
GETLOC	.EQU	010CH		;get cursor location
KILLBUF	.EQU	0106H		;kill key buffer
PUTCHAR	.EQU	01A3H		;output character to console (support esc. seq.)
SETLOC	.EQU	0109H		;set cursor location
;
;	Memory locations accessed by the Tandy WP-2 console interface
;
CONSTAT	.EQU	8403H		;console status bits
VRAM	.EQU	9900H		;beginning of 3,840 bytes of VRAM
;
;	Emit a character
;
PEMIT:	.WORD	$+2		;(EMIT) orphan
	POP	DE		;(E)<--(S1)LB = CHR
	LD	A,E		;what are we printing?
	CP	ACR		;carriage return?
	JR	Z,PCR		;yes
	CP	BSIN		;backspace?
	JR	Z,BCKSP		;yes
	CP	FF		;clear screen?
	JR	NZ,PEMIT1	;no
	PUSH	BC		;clear the screen
	CALL	CLS
	POP	BC
	JR	PEMITE		;done
PEMIT1:	CP	BELL		;bell?
	JR	NZ,PEMIT2	;no
	LD	A,0		;sound a low (0) bell (1=high)
	CALL	BEEP
	JR	PEMITE		;done
PEMIT2:	PUSH	BC		;emit a 'regular' character
	CALL	PUTCHAR
	POP	BC
PEMITE:	JNEXT
;
;	Deal with the backspace
;
BCKSP:	PUSH	BC
	CALL	GETLOC		;where is the cursor?
	LD	A,H		;at X=0?
	OR	A
	JR	Z,BCKSPE	;yes, nothing to do
	DEC	H		;cursor left one position
	CALL	SETLOC
	PUSH	HL
	LD	A,ABL		;emit space over old character
	CALL	PUTCHAR
	POP	HL
	CALL	SETLOC		;cursor left one position
BCKSPE:	POP	BC
	JNEXT
;
;	Read a key from the keyboard
;
PKEY:	PUSH	BC
	LD	HL,CONSTAT	;check if cursor enabled
	BIT	2,(HL)
	JR	Z,PKEY1		;yes
	XOR	A		;no, enable cursor
	CALL	CURSON
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
;
;	Execute a terminal carriage return and line feed.
;
;	Note that PUTCHAR only scrolls the display when printing normal
;	characters sequentially. Printing CR or LF only change the cursor
;	position, without checking whether the display should be scrolled as
;	a consequence :(
;
;	Also note that there is a bug in the BIOS where sending ESC 'K', which
;	should erase to the end of the line, only erases (80 - Y) characters,
;	rather than (80 - X) as intended, so we cannot use that
;
PCR:	PUSH	BC
	LD	A,0DH		;print CR
	CALL	PUTCHAR
	LD	A,0AH		;print LF
	CALL	PUTCHAR
	CALL	GETLOC		;where is the cursor
	LD	A,L		;check y-position
	CP	8		;less than 8?
	JR	C,PCRE		;yes, done
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
	LD	HL,7		;cursor to beginning of line 7
	CALL	SETLOC
PCRE:	POP	BC
	JNEXT
;
