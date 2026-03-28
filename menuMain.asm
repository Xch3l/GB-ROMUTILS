.DEFINE SRAM_KEY $0A

MainMenuCGB:
	.db 7 ; options
	dwp MainVBL
	dwp MainLoop
	dwp strMainTitle
	dwp strMainViewHeader
	dwp strMainBackupROM
	dwp strMainBackupSRAM
	dwp strMainRestoreSRAM
	dwp strMainCartOptions
	dwp strMainTestIR
	dwp strMainAbout
	dwp ViewHeader
	dwp BackupROM
	dwp BackupRAM
	dwp MenuNotAvailable; RestoreSRAM
	dwp CartMenu
	dwp TestIR
	dwp About_Init

MainMenuNoCGB:
	.db 6 ; options
	dwp MainVBL
	dwp MainLoop
	dwp strMainTitle
	dwp strMainViewHeader
	dwp strMainBackupROM
	dwp strMainBackupSRAM
	dwp strMainRestoreSRAM
	dwp strMainCartOptions
	dwp strMainAbout
	dwp ViewHeader
	dwp BackupROM
	dwp BackupRAM
	dwp MenuNotAvailable; RestoreSRAM
	dwp CartMenu
	dwp About_Init

MainVBL:
	in SYSFLAGS
	and $03
	cp $03
	jr NZ, +

	ld HL, BG0+$11
	ld A, GBA_ICON1
	ldi (HL), A
	inc A
	ldi (HL), A

+	; Display ROM title
	ld HL, ROMTITLE
	ld DE, BG0+$0201
	ld B, 16

	ld A, '['
	ld (DE), A
	inc DE

-	ldi A, (HL)
	ld (DE), A
	inc DE
	dec B
	jr NZ, -

	ld A, ']'
	ld (DE), A
	ret

MainLoop:
	; Check if running on a GBA
	in SYSFLAGS
	and $03
	cp $03
	gosubz CheckLogo

	ld HL, OAMTABLE

	; Get ROM Size
	ld A, (ROMSIZE)
	ld (HL), $28 ; y
	inc HL
	ld (HL), $98 ; x
	inc HL
	ldi (HL), A  ; t
	ld (HL), $00 ; a
	inc HL

	; Get SRAM Size
	ld A, (RAMSIZE)
	ld (HL), $30 ; y
	inc HL
	ld (HL), $98 ; x
	inc HL
	ldi (HL), A  ; t
	ld (HL), $00 ; a

	; Test comms
	in JPRESS
	bit _JP_SELECT, A
	jr NZ, @testSIO
	bit _JP_START, A
	jr NZ, HoldGBA
	ret

; Sends two bytes over SIO (Link Port) to test connection
@testSIO:
	SetIFLAGS IF_SERIAL

	; Send sync data
	ldp HL, @sioData
	ld B, 4
	ld C, <rSC

-	ldi A, (HL)
	gosub SIOWRITE
	dec B
	jr NZ, -

	RestoreIFLAGS
	ret

@sioData: ; Data to send and sync with receiver
	.db $55, $AA, "OK"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; AGB Hold - Standby routine for GameBoy Advance.
; The GBA will disconnect everything but HRAM when pulling the
; cart out so we need to do this to prevent it (except fancier)
HoldGBA:
	ldp HL, AGBHoldScreen
	ld DE, BG1
	gosub ScreenOff

	; Copy screen
-	ldi A, (HL)
	and A
	jr Z, +
	ld (DE), A
	inc DE
	jr -

+	; Clear the rest
	ld A, ' '
-	ld (DE), A
	inc DE
	bit 4, D
	jr NZ, -

	; Swap BG+OAM display
	in rLCDC
	xor LCDC_BG9C|LCDC_OBJ
	out rLCDC
	gosub ScreenOn

	; Set interrupt source
	SetIFLAGS IF_VBLANK

	ld C, <rJOYP
	outi $10 ; enable buttons
	call AGBHOLD

	; Swap BG+OAM display (again)
	in rLCDC
	xor LCDC_BG9C|LCDC_OBJ
	out rLCDC

	; Restore interrupt source
	RestoreIFLAGS
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Transfers a byte through SIO (Link Port)
;
; Before calling, SIO Interrupt must be enabled or this call
; will hang indefinitely
SIOWRITE:
	out rSB ; data to send
	out rSC, $83 ; enable transfer

	; Conserve power by waiting for interrupt
	out rIF, $00 ; clear ints
-	sleep
	in rSC
	rla
	jr C, -

	in rIF
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Checks amount of SRAM and shows a message if there's none.
; Returns amount in banks
CheckSRAM:
	; Check SRAM byte
	ld A, (RAMSIZE)
	cp 6 ; check if in range (0-5)
	jr NC, @invalidValue

	ldp HL, @sramBanks
	add L
	ld L, A
	ld A, (HL)
	and A
	ret NZ

@noSRAM:
	ldp DE, strNoSRAM
	jr +

@invalidValue:
	ldp DE, strInvalidSRAM
+	pop HL ; remove return point
	gosub InitPopup
	SetIFLAGS IF_VBLANK

	; Wait a bit
	ld D, 240 ; 5sec
-	out rIF, $00
	sleep
	gosub ReadInput
	and A
	jr NZ, +
	dec D
	jr NZ, -
+	gosub ClosePopup

	; Restore isource
	RestoreIFLAGS
	ret

@sramBanks:
	.db 0, 0, 1, 4, 16, 8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Menu callbacks
ViewHeader:
	goto HeaderView

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Backup ROM via SIO (Link port)
BackupROM:
	ldp DE, strDumpingROM
	gosub InitPopup

	; Wait VBlank
-	out rIF, $00
	sleep
	in rIF
	bit _IF_VBLANK, A
	jr Z, -

	; Setup sprites
	ld HL, $FE00
	ldp DE, @progressOAMs
	ld B, 12
-	ld A, (DE)
	ldi (HL), A
	inc DE
	dec B
	jr NZ, -

	; Get ROM banks
	ld A, (ROMSIZE)
	ld B, $02
	and A
	jr Z, +

	; Fix for bank count
-	sla B ; B <<= 1
	dec A
	jr NZ, -

+	ld HL, $0000 ; ROM pointer
	dec B ; minus home bank

	SetIFLAGS IF_VBLANK|IF_SERIAL

@nextBank:
	ld A, D
	ld ($3000), A ; bank hi
	ld A, E
	ld ($2000), A ; bank lo

@nextByte:
	ldi A, (HL)
	gosub SIOWRITE

@waitEvent:
	bit _IF_VBLANK, A
	jr Z, @checkSIO
	res _IF_VBLANK, A
	out rIF ; clear flag

	; Update progress
	ld A, B
	ld ($FE02), A
	ld A, H
	ld ($FE06), A
	ld A, L
	ld ($FE0A), A

	ld A, (BG1+33) ; update spinner
	inc A
	and $1F
	or $10
	ld (BG1+33), A

@checkSIO:
	in rSC
	rla ; bit 7, A
	jr C, @waitEvent

	; check ROM pointer
	bit 7, H
	jr Z, @nextByte
	ld H, $40
	inc DE
	dec B
	jr NZ, @nextBank

	; Change message
	ld HL, BG1+32
	ldp DE, strComplete
	out rIF, $00

	ld A, $20
	sleep ; wait VBlank
-	ldi (HL), A
	ld A, (DE)
	inc DE
	and A
	jr NZ, -

	; Clear the remaining space
	ld A, $20
-	ldi (HL), A
	bit 7, L
	jr Z, -

	; Clear OAMs
	gosub ClearOAMS

	ld B, 60 ; delay for 1 second
-	out rIF, $00
	sleep
	dec B
	jr NZ, -

	; Close message and restore ints
	gosub ClosePopup
	RestoreIFLAGS
	ret

@progressOAMs:
	.db $90, $84, $80, $00
	.db $90, $90, $00, $00
	.db $90, $98, $00, $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Backup SRAM via SIO (Link Port)
BackupRAM:
	gosub CheckSRAM
	out TEMP ; save SRAM bank count

	; Show progress message
	ldp DE, strDumpingSRAM
	gosub InitPopup

	; Wait VBlank
-	out rIF, $00
	sleep
	in rIF
	bit _IF_VBLANK, A
	jr Z, -

	; Set OAMs
	ldp HL, @progressOAMs
	ld DE, $FE00
	ld B, 12
-	ldi A, (HL)
	ld (DE), A
	inc DE
	dec B
	jr NZ, -

	; Get SRAM length
	in TEMP
	ld C, A

	; Enable SRAM
	ld A, SRAM_KEY
	ld ($0000), A

	; Set interrupts
	SetIFLAGS IF_VBLANK|IF_SERIAL

	; Copy SRAM
@nextBank:
	ld A, B ; B = 0 on start
	ld ($4000), A
	ld HL, $A000

@nextByte:
	ldi A, (HL)
	gosub SIOWRITE

@waitEvent:
	bit _IF_VBLANK, A
	jr Z, @checkSIO
	res _IF_VBLANK, A
	out rIF ; clear flag

	; Handle VBlank (update progress)
	ld A, C ; C = SRAM banks
	dec A
	ld ($FE02), A
	ld A, H
	ld ($FE06), A
	ld A, L
	ld ($FE0A), A

	ld A, (BG1+33) ; update spinner
	inc A
	and $1F
	or $10
	ld (BG1+33), A

@checkSIO:
	in rSC
	rla ; bit 7, A
	jr C, @waitEvent

	bit 6, H ; check if at $C000
	jr Z, @nextByte
	inc B ; increase bank number
	dec C ; decrease bank count
	jr NZ, @nextBank

	;; Send complete
	; Disable SRAM
	xor A
	ld ($0000), A

	; Change message
	ld HL, BG1+32
	ldp DE, strComplete
	out rIF, $00

	ld A, $20
	sleep ; wait VBlank
-	ldi (HL), A
	ld A, (DE)
	inc DE
	and A
	jr NZ, -

	; Clean the rest
	ld A, $20
-	ldi (HL), A
	bit 7, L
	jr Z, -

	; Clear OAMs
	gosub ClearOAMS

	ld B, 60 ; delay 1 second
-	out rIF, $00
	sleep
	dec B
	jr NZ, -

	; Close message and restore ints
	gosub ClosePopup
	RestoreIFLAGS

	ret

@progressOAMs:
	.db $90, $84, $80, $00
	.db $90, $90, $00, $00
	.db $90, $98, $00, $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
RestoreSRAM:
	gosub CheckSRAM
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Cart utilities
CartMenu:
	ldp DE, CartOptionsMenu
	goto InitSubmenu

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; IR Test menu
TestIR:
	ldp DE, IRMenu
	goto InitSubmenu
