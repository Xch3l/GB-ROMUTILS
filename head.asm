.EMPTYFILL $FF
.ROMBANKSIZE $4000
.ROMBANKS 2

.DEFINE SLOT_ROM0 0
.DEFINE SLOT_ROMX 1
.DEFINE SLOT_WRAM 2
.DEFINE SLOT_HRAM 3

.MEMORYMAP
	DEFAULTSLOT SLOT_ROM0
	SLOT SLOT_ROM0 $0000 $4000
	SLOT SLOT_ROMX $4000 $4000
	SLOT SLOT_WRAM $C000 $2000
	SLOT SLOT_HRAM $FF80 $007F
.ENDME

.INCLUDE "..\.common\regs.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ROM Board type defs (SRAM = battery backed RAM)

;       ID                       ; Max ROM ; Max RAM ; Notes
.DEFINE BOARD_ROM            $00 ; 32KB    ; none    ; 
.DEFINE BOARD_MBC1           $01 ; 2MB     ; none    ; 
.DEFINE BOARD_MBC1_RAM       $02 ; 2MB     ; 32KB    ; 
.DEFINE BOARD_MBC1_SRAM      $03 ; 2MB     ; 32KB    ; 
.DEFINE BOARD_MBC2           $05 ; 256KB   ; 256b    ; 512x4bit SRAM
.DEFINE BOARD_MBC2_SRAM      $06 ; 256KB   ; 256b    ; 512x4bit SRAM
.DEFINE BOARD_ROM_RAM        $08 ; 32KB    ; 8KB     ; 
.DEFINE BOARD_ROM_SRAM       $09 ; 32KB    ; 8KB     ; 
.DEFINE BOARD_MMM01          $0B ; 8MB     ; none    ; 
.DEFINE BOARD_MMM01_RAM      $0C ; 8MB     ; 128KB   ; 
.DEFINE BOARD_MMM01_SRAM     $0D ; 8MB     ; 128KB   ; 
.DEFINE BOARD_MBC3_RTC       $0F ; 2MB     ; none    ; 
.DEFINE BOARD_MBC3_RTC_SRAM  $10 ; 2MB     ; 64KB    ; 
.DEFINE BOARD_MBC3           $11 ; 2MB     ; none    ; 
.DEFINE BOARD_MBC3_RAM       $12 ; 2MB     ; 64KB    ; 
.DEFINE BOARD_MBC3_SRAM      $13 ; 2MB     ; 64KB    ; 
.DEFINE BOARD_MBC5           $19 ; 8MB     ; none    ; 
.DEFINE BOARD_MBC5_RAM       $1A ; 8MB     ; 128KB   ; 
.DEFINE BOARD_MBC5_SRAM      $1B ; 8MB     ; 128KB   ; 
.DEFINE BOARD_MBC5_RUMB      $1C ; 8MB     ; none    ; 
.DEFINE BOARD_MBC5_RUMB_RAM  $1D ; 8MB     ; 128KB   ; 
.DEFINE BOARD_MBC5_RUMB_SRAM $1E ; 8MB     ; 128KB   ; 
.DEFINE BOARD_MBC6           $20 ;         ; 32KB    ; implies SRAM; used in 1 game
.DEFINE BOARD_MBC7           $22 ;         ; 256b    ; imples Accelerometer, Rumble and Serial EEPROM
.DEFINE BOARD_POCKETCAM      $FC ;         ;         ; 
.DEFINE BOARD_TAMA5          $FD ;         ;         ; 
.DEFINE BOARD_HuC3           $FE ;         ; 32KB    ; implies RTC, IR and SRAM
.DEFINE BOARD_HuC1_SRAM      $FF ;         ; 32KB    ; implies IR and SRAM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; (S)RAM Size defs
.DEFINE RAM_NONE  $00
.DEFINE RAM_8KB   $02
.DEFINE RAM_32KB  $03 ; 4x8KB banks
.DEFINE RAM_64KB  $05 ; 8x8KB banks
.DEFINE RAM_128KB $04 ; 16x8KB banks

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Pseudo opcodes
.MACRO out
	.IF NARGS == 2
		.IF \2 == 0
			xor A
		.ELSE
			ld A, \2
		.ENDIF
	.ENDIF

	ldh (\1&255), A
.ENDM

.MACRO in
	ldh A, (\1&255)
.ENDM

.MACRO outi
	.IF NARGS == 1
		.IF \1 == 0
			xor A
		.ELSE
			ld A, \1
		.ENDIF
	.ENDIF

	.db $E2 ; ld ($FF00+C), A
.ENDM

.MACRO ini
	.db $F2 ; ld A, ($FF00+C)
.ENDM

.MACRO sleep
	halt
	nop
.ENDM

.MACRO suspend
	stop
	nop
.ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
.org $0038
	push AF
	out rIE, $00
	pop AF
-	sleep
	jr -

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ROM Header
.org $0100
	jr Reset

.org $0104 ; NINTENDO logo
NintendoLogo:
	.db $CE, $ED, $66, $66, $CC, $0D, $00, $0B
	.db $03, $73, $00, $83, $00, $0C, $00, $0D
	.db $00, $08, $11, $1F, $88, $89, $00, $0E
	.db $DC, $CC, $6E, $E6, $DD, $DD, $D9, $99
	.db $BB, $BB, $67, $63, $6E, $0E, $EC, $CC
	.db $DD, $DC, $99, $9F, $BB, $B9, $33, $3E

.org $0134 ; Game title
ROMTITLE:
	.db "ROMUTILS   "

.org $013F ; Manufacturer code
	.db " TAC"

.org $0143 ; CGB support flag
CGBFLAG:
	.db $80 ; yes

.org $0144 ; licensee code
LICENSEE:
	.db "IX"

.org $0146 ; SGB support flag
SGBFLAG:
	.db $00 ; no

.org $0147 ; Cartridge board type
BOARDTYPE:
	.db BOARD_MBC3_RTC
	;.db BOARD_ROM_SRAM

.org $0148 ; ROM size
ROMSIZE:
	.db $00 ; 32KB

.org $0149 ; RAM size
RAMSIZE:
	.db RAM_64KB

.org $014A ; Region code
REGION:
	.db $01 ; international

.org $014B ; "old licensee code"
	.db $33

.org $014C ; ROM version
VERSION:
	.db $00

.org $014D ; Header checksum
CHECKSUM:
	.COMPUTEGBCHECKSUM
	.COMPUTEGBCOMPLEMENTCHECK

.RAMSECTION "SYSTEM" SLOT SLOT_HRAM
	SYSFLAGS db
	FRAMENUM db
	JDOWN    db
	JPRESS   db
	TEMP     dsb 8
.ENDS

.DEFINE SF_VBLANK   7
.DEFINE SF_READY    6
.DEFINE SF_AGB    $03
.DEFINE SF_CGB    $01
.DEFINE SF_DMG    $00

.DEFINE OAMDMA   $FFF8
.DEFINE AGBHOLD  $FFC0
.DEFINE OAMTABLE $DF00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Misc. defines
.DEFINE VRAM  $8000
.DEFINE VRAM1 $8800
.DEFINE VRAM2 $9000
.DEFINE BG0   $9800
.DEFINE BG1   $9C00

.DEFINE _JP_DOWN   7
.DEFINE _JP_UP     6
.DEFINE _JP_LEFT   5
.DEFINE _JP_RIGHT  4
.DEFINE _JP_START  3
.DEFINE _JP_SELECT 2
.DEFINE _JP_B      1
.DEFINE _JP_A      0

.DEFINE JP_DOWN   1<<_JP_DOWN
.DEFINE JP_UP     1<<_JP_UP
.DEFINE JP_LEFT   1<<_JP_LEFT
.DEFINE JP_RIGHT  1<<_JP_RIGHT
.DEFINE JP_START  1<<_JP_START
.DEFINE JP_SELECT 1<<_JP_SELECT
.DEFINE JP_B      1<<_JP_B
.DEFINE JP_A      1<<_JP_A

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code
.org $0150
Reset:
	ld SP, $E000
	di

	cp $01 ; DMG/SGB?
	jr NZ, @checkGBA
	xor A
	jr @doneCheck

@checkGBA
	ld A, SF_CGB
	cp B
	jr NZ, @doneCheck

@isGBA:
	ld A, SF_AGB

@doneCheck:
	out SYSFLAGS

Start:
	xor A

	; Clear HRAM
	ld HL, SYSFLAGS+1
	ld B, $FFFE-SYSFLAGS
-	ldi (HL), A
	dec B
	jr NZ, -

	; Wait VBlank
	out rIF
	inc A
	out rIE
	xor A
	sleep

	; Set registers
	out rIE      ; disable interrupts
	out rLCDC    ; disable LCD
	out rIF      ; clear iflags
	out rSNDCTRL ; disable Audio
	out rSC      ; disable SIO
	dec A
	out rJOYP    ; disable input

	; Load tiles
	ld HL, VRAM
	ld DE, Tileset
	ld BC, _sizeof_Tileset
-	ld A, (DE)
	ldi (HL), A
	xor A
	ldi (HL), A
	inc DE
	dec BC
	ld A, B
	or C
	jr NZ, -

	; Set Color palettes and BG attributes
	in SYSFLAGS
	and $03
	jr Z, +

	ld HL, Palettes
	ld B, 16
	out rBGPI, $80
	out rOBPI

-	ldi A, (HL)
	out rBGPD
	out rOBPD
	dec B
	jr NZ, -

	out rVBK, 1
	ld HL, BG0
	ld B, 32
-	ldi (HL), A
	dec B
	jr NZ, -

	out rVBK, 0

	; Enable Double Speed
	in rKEY1
	bit 7, A
	jr NZ, + ; skip if set already

	out rKEY1, 1
	suspend
;;	; Clear VRAM
;;	ld HL, BG0
;;	ld A, $20
;;-	ldi (HL), A
;;	bit 5, H
;;	jr Z, -

+	; Move OAMs offscreen
	ld HL, OAMTABLE
	ld B, 40
	ld A, $F0
-	ldi (HL), A
	ldi (HL), A
	ldi (HL), A
	ldi (HL), A
	dec B
	jr NZ, -

	; Clear following stack space
-	ld (HL), $55
	inc L
	jr NZ, -

	; Copy OAMDMA routine
	ld HL, OAMDMAh
	ld DE, OAMDMA
	ld B, _sizeof_OAMDMAh
-	ldi A, (HL)
	ld (DE), A
	inc DE
	dec B
	jr NZ, -

	; Copy AGBHOLD routine
	ld HL, AGBHOLDh
	ld DE, AGBHOLD
	ld B, _sizeof_AGBHOLDh
-	ldi A, (HL)
	ld (DE), A
	inc DE
	dec B
	jr NZ, -

	; Copy MAIN code
	ld HL, RAMCODE
	ld DE, $C000
	ld BC, RAMCODE_END-RAMCODE
-	ldi A, (HL)
	ld (DE), A
	inc DE
	dec BC
	ld A, B
	or C
	jr NZ, -

	goto Main

OAMDMAh:
	outi
-	dec B
	jr NZ, -
	nop
	ret

AGBHOLDh:
	ld B, $0F

	; Wait until A+B are pressed
-	out rIF, $00
	sleep
	ini
	and B
	cp $0F-JP_A-JP_B
	jr NZ, -

	; Acknowledge
	ld A, TICK_ICON
	ld ($9CD0), A
	ld ($9CEF), A

-	; Now wait until they are released
	out rIF, $00
	sleep
	ini
	and B
	cp B
	jr NZ, -
	ret

Tileset:
	.INCBIN "1bpp.bin"

.DEFINE COLOR0 $7FFF
.DEFINE COLOR1 $2FF5
.DEFINE COLOR2 $2EA1
.DEFINE COLOR3 $0560

Palettes:
	.dw COLOR0, COLOR3, 0, 0
	.dw COLOR3, COLOR0, 0, 0

ENDOF_HEAD:
