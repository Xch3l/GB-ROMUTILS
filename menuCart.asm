.DEFINE SRAMBANKS TEMP
.DEFINE TESTVALUE TEMP+1

.DEFINE OAM_PATTERNBYTE $FE02
.DEFINE OAM_ADDRBANK    $FE06
.DEFINE OAM_ADDRHI      $FE0A
.DEFINE OAM_ADDRLO      $FE0E

CartOptionsMenu:
	.db 5
	dwp CartMenuVBL
	dwp CartMenuLoop
	; labels
	dwp strCartOptionsTitle ; title
	dwp strViewRTC
	dwp strTestSRAM
	dwp strTestRumble
	dwp strHashROM
	dwp strReturn
	; callbacks
	dwp ViewRTC
	dwp SRAMTest_Init ; TestSRAM
	dwp TestRumble
	dwp MenuNotAvailable; HashROM
	dwp ReturnSubmenu

CartMenuVBL:
	ret

CartMenuLoop:
	ret

ViewRTC:
	ld A, (BOARDTYPE)
	cp BOARD_MBC3_RTC
	jr Z, +
	cp BOARD_MBC3_RTC_SRAM
	jr NZ, @noRTC

+	; Init submenu
	ldp DE, RTCMenu
	goto InitSubmenu

@noRTC:
	ldp DE, strNoRTC
	gosub InitPopup

	SetIFLAGS IF_VBLANK

	ld E, 240 ; 5sec
-	out rIF, $00
	sleep
	gosub ReadInput
	and A
	jr NZ, +
	dec E
	jr NZ, -
+

	; Close message
	gosub ClosePopup

	RestoreIFLAGS
	ret

TestRumble:
	;[TODO] Check for applicable board type
	ldp DE, RumbleMenu
	goto InitSubmenu

TestSRAM:
	;[TODO] Take into account MBC2's 4bit SRAM
	;[TODO] ...and MBC7's serial EEPROM

	ldp DE, strSramTesting
	gosub InitPopup

	; Unlock SRAM
	ld A, SRAM_KEY
	ld ($0000), A

	; Run tests
	ld A, $AA
	gosub RunSRAMtest
	jr NZ, @endtest
	cpl   ; A = $55
	gosub RunSRAMtest
	jr NZ, @endtest
	xor A ; A = $00
	gosub RunSRAMtest
	jr NZ, @endtest
	dec A ; A = $FF
	gosub RunSRAMtest
	jr NZ, @endtest

@endtest:
	push AF
	push BC
	push DE
	push HL

	; Lock SRAM
	xor A
	ld ($0000), A

	gosub ClosePopup

	pop HL
	pop DE
	pop BC
	pop AF
	ret

RunSRAMtest:
	ld D, A ; keep value to test
	in SRAMBANKS ; get SRAM banks
	ld B, $00 ; current bank number
	ld C, A ; total bank count

	; wait for vblank
-	sleep
	in rIF
	bit _IF_VBLANK, A
	jr Z, -

	ld A, D ; show current pattern
	ld (OAM_PATTERNBYTE), A

@nextBank: ; set SRAM bank
	ld A, B
	ld ($4000), A
	ld HL, $A000

@nextByte:
	in rIF ; check vblank state
	bit _IF_VBLANK, A
	jr Z, @testValue
	res _IF_VBLANK, A
	out rIF

	; Update status
	ld A, B ; current bank number
	ld (OAM_ADDRBANK), A
	ld A, H ; address (high)
	ld (OAM_ADDRHI), A
	ld A, L ; address (low)
	ld (OAM_ADDRLO), A

@testValue:
	ld A, D
	ld (HL), A
	cp (HL)
	jr NZ, @error

	; invert pattern byte
	cpl
	ld D, A

	inc HL
	bit 6, H
	jr Z, @nextByte

	; invert pattern byte
	cpl
	ld D, A

	inc B
	dec C
	jr NZ, @nextBank
	ret

@error:
	ld C, 1 ; error state
	ret

HashROM:
	ret

strSramTesting: text "Testing…"
strSramTestError: text "Test failed"
strSramTestSuccess: text "Test success"

;----
; Full screen SRAM test
SRAMTest_Init:
	gosub CheckSRAM
	out SRAMBANKS

	;[TODO] Warn about potential data loss

	SetIFLAGS IF_VBLANK

	; Setup screen
	ldp HL, scrSRAMTest_Screen
	ld DE, BG0
	gosub InitScreen

	; Place OAMs
	ldp HL, oamSRAMTest
	ld DE, $FE00
	ld B, 16
-	ldi A, (HL)
	ld (DE), A
	inc DE
	dec B
	jr NZ, -

	; Remove placeholders
	ld A, $20
	ld HL, BG0+$0051
	ldi (HL), A
	ld (HL), A
	ld HL, BG0+$0070
	ldi (HL), A
	ldi (HL), A
	ld (HL), A

	gosub ScreenOn
	gosub TestSRAM ; run tests
	sleep ; wait vblank

	; Print result message
	bit 0, C
	jr Z, + ; success?

	; Display error address (pattern gets set beforehand)
	ld A, B
	ld (OAM_ADDRBANK), A
	ld A, H
	ld (OAM_ADDRHI), A
	ld A, L
	ld (OAM_ADDRLO), A
	ldp HL, strSramTestError
	jr ++

+	; Restore placeholders
	ld A, '-'
	ld HL, BG0+$0051
	ldi (HL), A
	ld (HL), A
	ld HL, BG0+$0070
	ldi (HL), A
	ldi (HL), A
	ld (HL), A

	gosub ClearOAMS
	ldp HL, strSramTestSuccess

++	; Copy string
	ld DE, BG0+$0101
-	ldi A, (HL)
	and A
	jr Z, @waitExit
	ld (DE), A
	inc DE
	jr -

@waitExit: ; Wait for key input
	out rIF, 0 ; clear pending ints
	sleep
	gosub ReadInput
	and JP_A|JP_B
	jr Z, @waitExit

	RestoreIFLAGS

	pop AF ; destroy previous return
	ld A, 1 ; preselect option
	ldp DE, CartOptionsMenu ; reinit menu
	goto InitMenu+1

;[TODO] Move this to AllStrings
scrSRAMTest_Screen:
	.db 4 ; lines
	text "SRAM Test"
	text ""
	text "Pattern         --"
	text "Addr           ---"
	text ""
	text ""

oamSRAMTest:
	.db $20, $98, $AA, $00 ; pattern
	.db $28, $84, $00, $00 ; addr bank
	.db $28, $90, $A0, $00 ; addr hi
	.db $28, $98, $00, $00 ; addr lo
