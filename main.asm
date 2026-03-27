.MACRO gosub
	call (\1-RAMCODE)+$C000
.ENDM

.MACRO goto
	jp (\1-RAMCODE)+$C000
.ENDM

.MACRO SetInt
	.REDEF PTR (\2-RAMCODE)+$C000

	ldp HL, \1
	ld (HL), <PTR
	inc HL
	ld (HL), >PTR
.ENDM

.MACRO SetIFLAGS
	in rIE
	push AF

	.IF NARGS == 1
		out rIE, \1
	.ENDIF

	out rIF, 0 ; clear pending
.ENDM

.MACRO RestoreIFLAGS
	pop AF
	out rIE
	out rIF, 0 ; clear pending
.ENDM

.INCLUDE "head.asm"

; Special defs for `ldp` macro
.DEFINE BC $10000
.DEFINE DE $20000
.DEFINE HL $40000
.DEFINE A  $80000

.MACRO ldp
	.IF NARGS != 2
		.PRINT "Missing argument\n  "
		.PRINT WLA_FILENAME
		.PRINT "\n"
		.FAIL
	;.printv WLA_FILENAME
	;.print "\n"
	.ENDIF

	.IF \1 == A
		.db $FA ; ld A, (nnnn)
	.ELSE
		.db ((\1>>13)&$F0)|$01 ; ld r16, nnnn
	.ENDIF
	.dw (\2-RAMCODE)+$C000
.ENDM

.MACRO lda
	.db $FA ; ld A, (nnnn)
	.dw (\1-RAMCODE)+$C000
.ENDM

.MACRO sta
	.db $EA ; ld (nnnn), A
	.dw (\1-RAMCODE)+$C000
.ENDM

.MACRO dwp
	.dw (\1-RAMCODE)+$C000
.ENDM

.DEFINE MAX_LABEL_LENGTH 18
.DEFINE MENUBAND_COLOR   $03
.DEFINE OPTION_COLOR     $0E
.DEFINE SCREEN_COLOR     $08

.DEFINE IDLE_TILE        $08
.DEFINE FILL_TILE        $09
.DEFINE DOTS             $0A
.DEFINE DIVIDER_TILE     $0B
.DEFINE GBA_ICON1        $0C
.DEFINE GBA_ICON2        $0D
.DEFINE BOX_ICON         $0E
.DEFINE TICK_ICON        $0F

; Misc. chars mapping
.ASCIITABLE
	MAP "•" = FILL_TILE
	MAP "Ø" = BOX_ICON
	MAP "…" = DOTS
.ENDA

.MACRO text
	.REPT NARGS
		.asc \1
		.SHIFT
	.ENDR

	.db 0
.ENDM

.SECTION "RAMCODE" SLOT SLOT_ROMX BANK 1
RAMCODE:

Main:
	out rLCDC, LCDC_WIN9C|LCDC_OBJ|LCDC_BG

	in SYSFLAGS
	cp SF_CGB
	jr Z, @colorMenu

	ldp DE, MainMenuNoCGB
	gosub InitMenu
	jr Main

@colorMenu:
	ldp DE, MainMenuCGB
	gosub InitMenu
	jr Main

	ret

ScreenOff:
	in rLCDC
	bit _LCDC_ON, A
	ret Z

	and $7F
	ld B, A
-	sleep
	in rIF
	bit _IF_VBLANK, A
	jr Z, -

	ld A, B
	out rLCDC
	ret

ScreenOn:
	out rIF, $00
	in rLCDC
	or LCDC_ON
	out rLCDC
	ret

CallPtr:
	jp (HL)

WaitInt:
	out rIF, $00
	sleep
	in rIF
	bit _IF_VBLANK, A
	call NZ, (VSync-RAMCODE)+$C000

	in rIF
	bit _IF_STAT, A
	.db $C4             ; {
STAT_INT: dwp NopRetn ; } call NZ, ptr

;;	in rIF
;;	bit _IF_SERIAL, A
;;	.db $C4            ; {
;;SIO_INT: dwp NopRetn ; } call NZ, ptr

NopRetn:
	ret

VSync:
	; Load OAMs
	ld HL, OAMTABLE
	in rLCDC
	bit 1, A
	jr Z, +
	ld A, H
	ld BC, $2846
	call OAMDMA

	.db $CD
VBLANK_INT: dwp NopRetn

	; Clear OAMs
	ld HL, OAMTABLE
	ld A, L
-	ld (HL), $C0
	add 4
	ld L, A
	cp $9C
	jr NZ, -

+	; Increase frame counter
	ld HL, FRAMENUM
	inc (HL)
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckLogo:
	ld HL, NintendoLogo
	ld B, $30
	ld A, $FF

	; CRC8 on all bytes
-	xor (HL) ; get byte
	inc HL

	ld C, 8
--	add A ; A << 1
		jr NC, +
		xor $31 ; poly
+		dec C
		jr NZ, --
	dec B
	jr NZ, -

	cp $7C
	ret Z

	goto HoldGBA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ReadInput:
	ld HL, rJOYP
	ld (HL), $20 ; select DPAD
	in JDOWN     ; get previous state [12t]
	ld C, A      ; keep it [4t]
	ld A, (HL)   ; read DPAD state [=16t]
	ld (HL), $10 ; select Buttons
	and $0F      ; remove selector bits [8t]
	swap A       ; set to high bits [8t]
	ld B, A      ; keep it [4t]
	ld A, (HL)   ; read Buttons state [=20t]
	ld (HL), H   ; disable
	and $0F      ; remove selector bits
	or B         ; combine with prevous read
	cpl          ; invert
	out JDOWN    ; save it

	ld B, A
	ld A, C
	xor B
	and B
	ld C, A
	out JPRESS

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PutHex:
	ld B, A
	swap A
	gosub PutHexLo
	ld A, B

PutHexLo:
	and 15
	add $90
	daa
	adc $40
	daa

	ldi (HL), A
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copies a string of text to VRAM (mostly used by menu interface)
;   DE = Source address pointer
;   HL = Target address
;   B  = Max length
CopyText:
	ld A, (DE)
	out TEMP
	inc DE
	ld A, (DE)
	inc DE
	push DE

	ld D, A
	in TEMP
	ld E, A

	; Copy text
-	ld A, (DE)  ; get next char
	inc DE
	and A       ; check for \0
	jr Z, +     ;   skip if so
	ldi (HL), A ; write it
	dec B
	jr NZ, -

	; skip to next \0
-	ld A, (DE)
	inc DE
	and A
	jr NZ, -

+	pop DE
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Converts a number (between 0 and 511) to its BCD representation
;   HL   Pointer to value
;  - or -
;   BC   Value
ConvertBCD:
	ld C, (HL)
	inc HL
	ld B, (HL)

ToBCD:
	ld A, C
	swap A
	and $0F
	bit 0, B
	jr Z, +
	dec B
	add 16
+	add A ; A * 2

	; Index into table of 16s
	push BC
	ldp HL, BcdTable
	ld B, $00
	ld C, A
	add HL, BC
	pop BC

	; convert value
	ld A, C
	and 15
	add 0
	daa
	add (HL)
	daa
	ld C, A ; low byte
	inc HL

	ld A, B
	adc 0
	daa
	add (HL)
	daa
	ld B, A ; high byte

	ret

BcdTable:
	.dw $0000, $0016, $0032, $0048, $0064, $0080, $0096, $0112
	.dw $0128, $0144, $0160, $0176, $0192, $0208, $0224, $0240

	.dw $0256, $0272, $0288, $0304, $0320, $0336, $0352, $0368
	.dw $0384, $0400, $0416, $0432, $0448, $0464, $0480, $0496

BCDBUF:
	.dw $0000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
AnimateIdleIcon:
	in FRAMENUM
	and 7
	ret Z

	ldp HL, IdleTile
	in FRAMENUM
	rra
	rra
	rra
	and 7
	ld B, 0
	ld C, A
	add HL, BC
	ld B, H
	ld C, L

	ld HL, (IDLE_TILE<<4)|$9000
	ld D, 8
-	ld A, (BC)
	ldi (HL), A
	xor A
	ldi (HL), A
	inc BC
	dec D
	jr NZ, -

	; Place idle tile
	ld HL, BG0+19
	ld (HL), IDLE_TILE
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Menu interface
MenuRef:     .dw $0000
MenuIndex:   .db $00
MenuOptions: .db $00
MenuUpdate:  .dw NopRetn
MenuLoop:    .dw NopRetn
MenuSelect:  .dw NopRetn

MenuVBlank:
	gosub AnimateIdleIcon ; update "idle activity" icon

	; Run current menu's "update" routine
	ldp HL, MenuUpdate
	ldi A, (HL)
	ld H, (HL)
	ld L, A
	gosub CallPtr

	; Highlight current option
	gosub MenuHighlight
	ret

ReturnSubmenu:
	pop AF ; remove previous call
	pop AF ; restore previous option
	pop DE ; restore last menu
	jr InitMenu+1

InitSubmenu:
	pop HL ; remove previous call

	; Keep previous menu
	ldp HL, MenuRef
	ldi A, (HL)
	ld H, (HL)
	ld L, A
	lda MenuIndex
	push HL
	push AF

; HL = Menu ptr
InitMenu:
	xor A

	; Init menu
	ldp HL, MenuRef
	ld (HL), E
	inc HL
	ld (HL), D
	inc HL
	ldi (HL), A ; set option index

	gosub ScreenOff

	; Load info
	ld A, (DE)
	ld C, A ; keep option count
	ld B, 5
-	inc DE
	ldi (HL), A
	ld A, (DE)
	dec B
	jr NZ, -

	; Load title
	ld HL, BG0
	ld B, MAX_LABEL_LENGTH
	ld A, $20
	ldi (HL), A
	gosub CopyText

	; Clear remaining space + one extra line
	ld A, 46
	add B
	ld B, A
	ld A, $20
-	ldi (HL), A
	dec B
	jr NZ, -

	; Load option labels
-	ld B, MAX_LABEL_LENGTH
		gosub CopyText

		ld A, 14
		add B
		ld B, A
		ld A, $20
--	ldi (HL), A
		dec B
		jr NZ, --

	dec C
	jr NZ, -

	; Clear the rest
	;ld A, $20 ; take it from before
-	ldi (HL), A
	bit 2, H
	jr Z, -

	; Capture options ptr
	ldp HL, MenuSelect
	ld (HL), E
	inc HL
	ld (HL), D

	out rBGP, $00
	out rOBP0
	out rOBP1

	out rIF, $00
	out rSTAT, STAT_LYCINT
	out rIE, IF_VBLANK|IF_STAT
	in rLCDC
	set _LCDC_ON, A
	out rLCDC;, LCDC_ON|LCDC_OBJ|LCDC_BG

	SetInt VBLANK_INT, MenuVBlank

LoopMenu:
	gosub WaitInt
	gosub ReadInput
	ldp HL, MenuOptions
	ldd A, (HL)
	ld B, A
	ld A, (HL)

	bit _JP_DOWN, C
	jr Z, +
	inc A
	cp B
	jr C, ++
	xor A
	jr ++

+	bit _JP_UP, C
	jr Z, +
	sub 1
	jr NC, ++
	ld A, B
	dec A
++	ld (HL), A

+	bit _JP_A, C
	jr Z, +

	ld B, $00
	add A
	ld C, A

	ldp HL, MenuSelect
	ldi A, (HL)
	ld H, (HL)
	ld L, A
	add HL, BC

	ldi A, (HL)
	ld H, (HL)
	ld L, A

	sleep
	ld A, $20
	ld (BG0+19), A
	gosub CallPtr
	goto LoopMenu

+	; on-menu loop handler
	ldp HL, MenuLoop
	ldi A, (HL)
	ld H, (HL)
	ld L, A
	gosub CallPtr
	goto LoopMenu

MenuHighlight:
	; get option scanline
	lda MenuIndex
	add A
	add A
	add A
	add 16
	ld B, A

	in SYSFLAGS
	and $03
	jr NZ, @colorMode

	out rIF, $00 ; menu header band
	out rBGP, MENUBAND_COLOR
	out rOBP0
	out rLYC, 8
	sleep
	out rIF, $00
	out rBGP, SCREEN_COLOR
	out rOBP0

	; change highlight
	out rIF, $00 ; clear iflags
	ld A, B
	out rLYC
	sleep
	out rIF, $00
	out rBGP, OPTION_COLOR
	out rOBP0
	ld A, B
	add 8
	out rLYC
	sleep
	out rIF, $00
	out rBGP, SCREEN_COLOR
	out rOBP0
	ret

@colorMode:
	;; should be in VBlank by now
	dec B

	ldp HL, @titlePalette
	gosub @setPalette

	; wait until scanline 8
	out rIF, $00 ; clear ints
	out rLYC, 7
	sleep

	; active spin
	ld D, $1C
-	dec D
	jr NZ, -

	ldp HL, @screenPalette
	gosub @setPalette

	; Wait until option scanline
	out rIF, $00
	ld A, B
	out rLYC
	sleep

	ld D, $1B
-	dec D
	jr NZ, -

	add 8
	out rLYC
	ldp HL, @optionPalette
	gosub @setPalette
	out rIF, $00
	sleep

	ld D, $1C
-	dec D
	jr NZ, -
	ldp HL, @screenPalette
	gosub @setPalette

	out rIF, $00
	ret

@setPalette:
	out rBGPI, $80 ; set writing mode
	out rOBPI

	ld C, 4
-	ldi A, (HL)
	out rBGPD
	out rOBPD
	dec C
	jr NZ, -
	ret

@titlePalette:  .dw COLOR0, COLOR1
@screenPalette: .dw COLOR0, COLOR2
@optionPalette: .dw COLOR1, COLOR3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Popup stuff (uses Window)
InitPopup:
	SetIFLAGS IF_VBLANK
	ld HL, BG1 ; set BG pointer, counter and tile before
	ld B, 32   ; sleeping to gain some cycles
	ld A, DIVIDER_TILE
	sleep
	;gosub ScreenOff

	; Make divider
-	ldi (HL), A
	dec B
	jr NZ, -

	; Write space
	ld A, $20
	ldi (HL), A

	; Write message
	ld B, 18 ; maxlen
-	ld A, (DE)
	inc DE
	and A
	jr Z, @clear
	ldi (HL), A
	jr NZ, -

	; Skip until next NUL
-	ld A, (DE)
	and A
	jr NZ, -

	; Clear next lines
@clear:
	ld A, 32
	add B
	ld B, A
	ld A, ' '
-	ldi (HL), A
	dec B
	jr NZ, -

	; Enable Window and LCD
	out rWX, $07
	out rWY, $90
	in rLCDC
	set _LCDC_WINDOW, A
	out rLCDC
	gosub ScreenOn

	; Animate sliding up
	ld A, $90 ; WY
	ld B, $08

@nextStep:
	out rWY
	out rIF, $00
	sleep

	in rWY
	sub B
	dec B
	cp $78
	jr NC, @nextStep
	out rWY, $78

	; Recover isource
	RestoreIFLAGS
	ret

ClosePopup:
	; Change isource
	SetIFLAGS IF_VBLANK ; vblank only

	; Slide down
	ld B, 1
-	out rIF, $00
	sleep
	in rWY
	add B
	out rWY
	inc B
	cp $90
	jr C, -

	; Restore isource
	RestoreIFLAGS
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Direct OAM clearing routine
ClearOAMS:
	ld HL, $FE00
	ld A, L

-	ld (HL), $F0
	add 4
	ld L, A
	cp $A0
	jr NZ, -
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Static screen uploader
InitScreen:
	ld C, (HL) ; line count
	inc HL

	gosub ScreenOff

	ld A, $20
	ld (DE), A
	inc DE

-	ld B, 20 ; max width
--	ldi A, (HL)
		and A
		jr Z, +
		ld (DE), A
		inc DE
		dec B
		jr NZ, --
+	ld A, 12
	add B
	ld B, A
	ld A, $20
--	ld (DE), A
		inc DE
		dec B
		jr NZ, --

	dec C
	jr NZ, -

-	ld (DE), A
	inc DE
	bit 2, D
	jr Z, -

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Menu code
.include "menuMain.asm"
.include "menuHeader.asm"
.include "menuCart.asm"
.include "menuRTC.asm"
.include "menuIR.asm"
.include "menuAbout.asm"
.include "AllStrings.asm"

IdleTile:
	.db 3, 3, 3, 3, 0, 0, 0, 0
	.db 3, 3, 3, 3, 0, 0, 0

RAMCODE_END:
.ENDS
