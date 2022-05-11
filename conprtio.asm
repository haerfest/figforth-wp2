;  CP/M CONSOLE & PRINTER INTERFACE
;
; Last update:
;
; 850511 - Saved BC' prior to CP/M calls
; 841010 - Saved IX & IY prior to CP/M calls
; 840909 - Converted all BIOS calls to BDOS calls for compatibility
;          with CP/M 3.0
;
;
;
LSTOUT	.EQU	05H		;printer output
DCONIO	.EQU	06H		;direct console I/O
;
RUBOUT	.EQU	7FH
INPREQ	.EQU	0FFH		;DCONIO input request
;
EPRINT:	.BYTE	0		;printer flag
				;0=disabled, 1=enabled
;
#IFDEF WP2
;
BEEP	.EQU	0121H		;W beep a buzzer
CHARGET	.EQU	0103H		;W get one character (wait for input)
CHKCNCL	.EQU	0124H		;W check that CNCL key is pressed now
CLS	.EQU	011EH		;W clear screen
CURSON	.EQU	010FH		;W set cursor on/off
GETLOC	.EQU	010CH		;W get cursor location
KILLBUF	.EQU	0106H		;W kill key buffer
PUTCHAR	.EQU	01A3H		;W output character to console (support esc. seq.)
SETLOC	.EQU	0109H		;W set cursor location
;
CONSTAT	.EQU	8403H		;W console status bits
CURSORX	.EQU	8358H		;W cursor X position
VRAM	.EQU	9900H		;W beginning of 3,840 bytes of VRAM
;
;
PEMIT:	.WORD	$+2		;(EMIT) orphan
	POP	DE		;(E)<--(S1)LB = CHR
	LD	A,E
	CP	ACR		;W carriage return?
	JR	Z,PCR
	CP	BSIN		;W backspace?
	JR	Z,BCKSP
	CP	FF		;W clear screen?
	JR	NZ,PEMIT1
;
	PUSH	BC
	CALL	CLS
	POP	BC
	JR	PEMITE
;
PEMIT1:	CP	BELL		;W bell?
	JR	NZ,PEMIT2
;
	LD	A,0		;W 0=low/1=high beep
	CALL	BEEP
	JR	PEMITE
;
PEMIT2:	PUSH	BC
	CALL	PUTCHAR
	POP	BC
PEMITE:	JNEXT
;
BCKSP:	PUSH	BC
	CALL	GETLOC		;W where is the cursor?
	LD	A,H		;W at X=0?
	OR	A
	JR	Z,BCKSPE	;W yes, nothing to do
	DEC	H		;W cursor left one position
	CALL	SETLOC
	PUSH	HL
	LD	A,ABL		;W space over old character
	CALL	PUTCHAR
	POP	HL
	CALL	SETLOC		;W back again
BCKSPE:	POP	BC
	JNEXT
;
PKEY:	PUSH	BC
	LD	HL,CONSTAT	;W check if cursor enabled
	BIT	2,(HL)
	JR	Z,PKEY1		;W yes
	XOR	A		;W enable cursor
	CALL	CURSON
PKEY1:	CALL	CHARGET
	LD	L,H
	LD	H,0
	POP	BC
	JHPUSH
;
PQTER:	LD	HL,0		;W assume CNCL not pressed
	CALL	CHKCNCL		;W CNCL pressed now?
	JR	NC,PQTERE	;W no, end
PQTER1:	CALL	CHKCNCL		;W wait until CNCL released
	JR	C,PQTER1
	CALL	KILLBUF		;W clear keyboard buffer
	LD	HL,1		;W signal CNCL was pressed
PQTERE:	JHPUSH
;
; "Execute a terminal carriage return and line feed."
;
; Note that PUTCHAR only scrolls the display when printing normal characters
; sequentially. Printing CR or LF only change the cursor position, without
; checking whether the display should be scrolled as a consequence :(
;
; Also note that there is a bug in the BIOS where sending ESC 'K', which should
; erase to the end of the line, only erases (80 - Y) characters, rather than
; (80 - X) as intended, so we cannot use that
;
PCR:	PUSH	BC
	LD	A,0DH		;W print CR
	CALL	PUTCHAR
	LD	A,0AH		;W print LF
	CALL	PUTCHAR
	CALL	GETLOC		;W where is the cursor
	LD	A,L		;W check y-position
	CP	8		;W less than 8?
	JR	C,PCRE		;W yes, end
	LD	BC,7*480	;W copy 7 lines
	LD	HL,VRAM+480	;W from lines 1-7
	LD	DE,VRAM		;W to lines 0-6
	LDIR
	LD	BC,480-1	;W erase last line
	LD	HL,VRAM+(7*480)
	LD	DE,VRAM+(7*480)+1
	XOR	A
	LD	(HL),A
	LDIR
	LD	HL,7		;W cursor at beginning of line 7
	CALL	SETLOC
PCRE:	POP	BC
	JNEXT
;
#ELSE
;
SYSENT:	PUSH	BC
	PUSH	DE
	PUSH	HL
	PUSH	IX
	PUSH	IY
	exx
	push	bc		;save ip (if used as such)
	exx
	CALL	BDOSS		;perform function (C)
	exx
	pop	bc		;restore ip
	exx
	POP	IY
	POP	IX
	POP	HL
	POP	DE
	POP	BC
	RET
;
CSTAT:	PUSH	BC
	LD	C,DCONIO	;direct console I/O
	LD	E,INPREQ	;input request
	CALL	SYSENT		;any CHR typed?
	POP	BC		;if yes, (A)<--CHAR
	RET			;else    (A)<--00H (ignore CHR)
;
CIN:	PUSH	BC
	LD	C,DCONIO	;direct console I/O
	LD	E,INPREQ	;request input
CINLP:	CALL	SYSENT		;(A)<--CHR (or 0 if nothing typed)
	OR	A
	JR	Z,CINLP		;wait for CHR to be typed
	CP	RUBOUT
	JR	NZ,CIN1
	LD	A,BSOUT		;convert RUB to ^H
CIN1:	RES	7,A		;(MSB)<--0
	POP	BC
	RET
;
COUT:	PUSH	BC
	PUSH	DE		;save (E) = CHR
	LD	C,DCONIO	;direct console output
	CALL	SYSENT		;send (E) to CON:
	POP	DE
	POP	BC
	RET
;
POUT:	PUSH	BC
	LD	C,LSTOUT
	CALL	SYSENT		;send (E) to LST:
	POP	BC
	RET
;
CPOUT:	CALL	COUT		;send (E) to console
	LD	A,(EPRINT)
	OR	A		;if (EPRINT) <> 0
	CALL	NZ,POUT		;send (E) to LST:
	RET
;
;	FORTH TO CP/M SERIAL I/O INTERFACE
;
PQTER:	CALL	CSTAT
	LD	HL,0
	OR	A		;CHR TYPED?
	JR	Z,PQTE1		;NO
	INC	L		;YES, (S1)<--TRUE
PQTE1:	JHPUSH
;
PKEY:	CALL	CIN		;READ CHR FROM CONSOLE
	CP	DLE		;^P?
	LD	E,A
	JR	NZ,PKEY1	;NO
	LD	HL,EPRINT
	LD	E,ABL		;(E)<--BLANK
	LD	A,(HL)
	XOR	01H		;TOGGLE (EPRINT) LSB
	LD	(HL),A
PKEY1:	LD	L,E
	LD	H,0
	JHPUSH			;(S1)LB<--CHR
;
PEMIT:	.WORD	$+2		;(EMIT) orphan
	POP	DE		;(E)<--(S1)LB = CHR
	LD	A,E
	CP	BSOUT
	JR	NZ,PEMIT1
	CALL	COUT		;backspace
	LD	E,ABL		;blank
	CALL	COUT		;erase CHR on CON:
	LD	E,BSOUT		;backspace
PEMIT1:	CALL	CPOUT		;send CHR to CON:
				;and LST: if (EPRINT)=01H
	JNEXT
;
PCR:	LD	E,ACR
	CALL	CPOUT		;output CR
	LD	E,LF
	CALL	CPOUT		;and LF
	JNEXT
;
;
;
#ENDIF