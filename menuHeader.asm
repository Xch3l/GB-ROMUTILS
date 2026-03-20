HeaderScreen:
	.db 13 ; lines
	text "ROM Header"
	text ""
	text "[................]"
	text ""
	text "Licensee       :.."
	text "ROM Size"
	text "RAM Size"
	text "CGB Compat"
	text "SGB Compat"
	text "Region"
	text "Cart type"
	text "Version"
	text "Checksum       :"

HeaderView:
	ldp HL, HeaderScreen
	ld DE, BG0
	gosub InitScreen

	; Set GBA icon (if applicable)
	in SYSFLAGS
	and $03
	cp $03
	jr NZ, +
	ld HL, BG0+$11
	ld A, GBA_ICON1
	ldi (HL), A
	inc A
	ldi (HL), A

+	; Replace VBL handler
	ldp HL, VBLANK_INT
	ldi A, (HL)
	ld H, (HL)
	ld L, A
	push HL
	SetInt VBLANK_INT, hvVBlank

	; Clear inputs
	ld A, $FF
	ld (JDOWN), A

	gosub ScreenOn
	sleep
	goto hvLoop

hvVBlank:
	gosub AnimateIdleIcon ; update "idle activity" icon

	; Fill in details
	ld HL, ROMTITLE ; ROM title
	ld DE, BG0+$42
	ld B, 16
-	ldi A, (HL)
	ld (DE), A
	inc DE
	dec B
	jr NZ, -

	ld HL, CGBFLAG
	ldi A, (HL) ; CGB Flag
	bit 7, A
	ld A, BOX_ICON
	jr Z, +
	inc A
+	ld (BG0+$F2), A

	ldi A, (HL)
	ld (BG0+$91), A
	ldi A, (HL)
	ld (BG0+$92), A

	ld A, (HL) ; SGB Flag
	cp $03
	ld A, BOX_ICON
	jr NZ, +
	inc A
+	ld (BG0+$112), A

	ld A, (REGION)
	and A
	ld A, 'J' ; J = Japan
	jr Z, +
	dec A ; I = International
+	ld (BG0+$132), A

	; Board type
BRDTYPPTR:
	ld HL, 0
	ld DE, BG0+$14E
	gosub hvCopyLabel

	; ROM Size
ROMSIZEPTR:
	ld HL, 0
	ld DE, BG0+$0AE
	gosub hvCopyLabel

	; ROM Size
RAMSIZEPTR:
	ld HL, 0
	ld DE, BG0+$0CE
	;goto hvCopyLabel

hvCopyLabel:
	ld B, 5
-	ldi A, (HL)
	ld (DE), A
	inc DE
	dec B
	jr NZ, -
	ret

hvLoop:
	; Check if running on a GBA
	in SYSFLAGS
	and $03
	cp $03
	call Z, (CheckLogo-RAMCODE)+$C000

	; do the stuff
	gosub WaitInt
	gosub ReadInput

	and JP_A|JP_B ;bit _JP_B, C ; return if B was pressed
	jp NZ, (hvReturn-RAMCODE)+$C000

	in SYSFLAGS
	and $03
	cp $03
	jr NZ, +
	out rIF, $00 ; menu header band
	out rBGP, MENUBAND_COLOR
	out rOBP0
	out rLYC, 8
	sleep
	out rIF, $00
	out rBGP, $80
	out rOBP0
+

	; OAM stuff
	ld HL, OAMTABLE
	ld BC, $0098 ; B=attr C=xpos

	ld A, (VERSION)
	ld (HL), $68    ; y
	inc HL
	ld (HL), C      ; x
	inc HL
	ldi (HL), A     ; t
	ld (HL), B      ; a
	inc HL

	ld A, (CHECKSUM)
	ld (HL), $70    ; y
	inc HL
	ld (HL), $80    ; x
	inc HL
	ldi (HL), A     ; t
	ld (HL), B      ; a
	inc HL

	ld A, (CHECKSUM+2)
	ld (HL), $70    ; y
	inc HL
	ld (HL), $90    ; x
	inc HL
	ldi (HL), A     ; t
	ld (HL), B      ; a
	inc HL

	ld A, (CHECKSUM+1)
	ld (HL), $70    ; y
	inc HL
	ld (HL), $98    ; x
	inc HL
	ldi (HL), A     ; t
	ld (HL), B      ; a
	inc HL

	ld A, ($014B) ; "Old licensee code"
	ld (HL), $30    ; y
	inc HL
	ld (HL), $80    ; x
	inc HL
	ldi (HL), A     ; t
	ld (HL), B      ; a
	inc HL

	; Get label pointers
	ldp HL, ROMTYPES
	ld A, (BOARDTYPE)
	cp $80
	jr C, +
	add $30
+	ld B, $00
	ld C, A
	add HL, BC
	ld A, (HL)

	ldp DE, BRDTYPPTR+1
	ldp BC, ROMTYPES@labels
	gosub hvGetLabel

	ldp HL, ROMSIZES
	ld A, (ROMSIZE)
	cp 9
	jr C, +
	ld A, 55
	jr ++

+	ld B, $00
	ld C, A
	add HL, BC
	ld A, (HL)

++
	ldp DE, ROMSIZEPTR+1
	ldp BC, SizeLabels
	gosub hvGetLabel

	ldp HL, RAMSIZES
	ld A, (RAMSIZE)
	cp 6
	jr C, +
	ld A, 55
	jr ++

+	ld B, $00
	ld C, A
	add HL, BC
	ld A, (HL)

++
	ldp DE, RAMSIZEPTR+1
	ldp BC, SizeLabels
	gosub hvGetLabel

	goto hvLoop

hvGetLabel:
	add C
	ld C, A
	jr NC, +
	inc B

+	ld H, D
	ld L, E
	ld (HL), C
	inc HL
	ld (HL), B
	ret

hvReturn:
	pop HL
	pop HL
	pop HL
	goto Main

ROMSIZES:
	.db 10, 15, 20, 25, 30, 35, 40, 45, 50

RAMSIZES:
	.db 00, 55, 05, 10, 20, 15

ROMTYPES:
	;    0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
	.db  0,  5,  5,  5, 60, 10, 10, 60,  0,  0, 60, 35, 35, 35, 60, 15
	.db 15, 15, 15, 15, 60, 60, 60, 60, 60, 20, 20, 20, 20, 20, 20, 60
	.db 25, 60, 30, 60, 60, 60, 60, 60, 60, 60, 60, 60, 40, 45, 55, 50

@labels:
	.db "  ROM" ; 0  | 00 08 09
	.db " MBC1" ; 5  | 01 02 03
	.db " MBC2" ; 10 | 05 06
	.db " MBC3" ; 15 | 0F 10 11 12 13
	.db " MBC5" ; 20 | 19 1A 1B 1C 1D 1E
	.db " MBC6" ; 25 | 20
	.db " MBC7" ; 30 | 22
	.db "MMM01" ; 35 | 0B 0C 0D
	.db "  CAM" ; 40 | FC
	.db "TAMA5" ; 45 | FD
	.db " HuC1" ; 50 | FF
	.db " HuC3" ; 55 | FE
	.db "?????" ; 60

;;                   | RAM | BATT | RTC | RUM | SENS | CAM
;; 00  ROM           |     |      |     |     |      |
;; 01  MBC1          |     |      |     |     |      |
;; 02  MBC1          |  x  |      |     |     |      |
;; 03  MBC1          |  x  |  x   |     |     |      |
;; 05  MBC2          |     |      |     |     |      |
;; 06  MBC2          |     |  x   |     |     |      |
;; 08  ROM           |  x  |      |     |     |      |
;; 09  ROM           |  x  |  x   |     |     |      |
;; 0B  MMM01         |     |      |     |     |      |
;; 0C  MMM01         |  x  |      |     |     |      |
;; 0D  MMM01         |  x  |  x   |     |     |      |
;; 0F  MBC3          |     |  x   |  x  |     |      |
;; 10  MBC3          |  x  |  x   |  x  |     |      |
;; 11  MBC3          |     |      |     |     |      |
;; 12  MBC3          |  x  |      |     |     |      |
;; 13  MBC3          |  x  |  x   |     |     |      |
;; 19  MBC5          |     |      |     |     |      |
;; 1A  MBC5          |  x  |      |     |     |      |
;; 1B  MBC5          |  x  |  x   |     |     |      |
;; 1C  MBC5          |     |      |     |  x  |      |
;; 1D  MBC5          |  x  |      |     |  x  |      |
;; 1E  MBC5          |  x  |  x   |     |  x  |      |
;; 20  MBC6          |     |      |     |     |      |
;; 22  MBC7          |  x  |  x   |     |  x  |   x  |
;; FC  Pocket Camera |  x  |  x   |     |     |      |  x

SizeLabels:   ; offs   rom sram
	.db " none" ; 0          00
	.db "  8KB" ; 5          10
	.db " 32KB" ; 10     00  15
	.db " 64KB" ; 15     05  25
	.db "128KB" ; 20     10  20
	.db "256KB" ; 25     15
	.db "512KB" ; 30     20
	.db "  1MB" ; 35     25
	.db "  2MB" ; 40     30
	.db "  4MB" ; 45     35
	.db "  8MB" ; 50     40
	.db "<inv>" ; 55     45  05
