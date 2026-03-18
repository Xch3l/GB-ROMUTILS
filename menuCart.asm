.DEFINE SRAMBANKS TEMP
.DEFINE TESTVALUE TEMP+1

CartOptionsMenu:
	.db 5
	dwp CartMenuVBL
	dwp CartMenuLoop
	; labels
	dwp strCartOptionsTitle ; title
	dwp strViewRTC
	dwp strTestRumble
	dwp strTestSRAM
	dwp strHashROM
	dwp strReturn
	; callbacks
	dwp ViewRTC
	dwp TestRumble
	dwp TestSRAM
	dwp HashROM
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

	; Keep isources
	in rIE
	push AF
	out rIE, IF_VBLANK

	ld D, 240 ; 5sec
-	out rIF, $00
	sleep
	gosub ReadInput
	and A
	jr NZ, +
	dec D
	jr NZ, -
+

	; Close message
	gosub ClosePopup

	; Restore isources
	pop AF
	out rIE
	ret

TestRumble:
	ret

TestSRAM:
	;[TODO] Warn about potential data loss
	;[TODO] Take into account MBC2's 4bit SRAM

	gosub CheckSRAM
	out SRAMBANKS

	ldp DE, strSramTesting
	gosub InitPopup

	; Unlock SRAM
	ld A, $AA
	ld ($0000), A

	gosub @run

	; Lock SRAM
	xor A
	ld ($0000), A

	ret

@run:
	ld A, $AA
	gosub RunSRAMtest
	cpl   ; A = $55
	gosub RunSRAMtest
	xor A ; A = $00
	gosub RunSRAMtest
	dec A ; A = $FF
	gosub RunSRAMtest

	; Lock SRAM
	xor A
	ld ($0000), A

	; Display success message
	ldp DE, strSramTestSuccess
	gosub InitPopup

	; Wait to dismiss
-	sleep
	gosub ReadInput
	bit _JP_A, A
	jr Z, -

	goto ClosePopup
	;gosub ClosePopup
	;ret

RunSRAMtest:
	out TESTVALUE ; keep value to test
	ld B, $00 ; current bank number
	in SRAMBANKS ; get SRAM banks
	ld C, A

@nextBank: ; set SRAM bank
	ld A, B
	ld ($4000), A
	ld HL, $A000
	in TESTVALUE

@nextByte:
	ld (HL), A
	cp (HL)
	jr NZ, @error
	inc HL
	bit 6, H
	jr Z, @nextByte

	inc B
	dec C
	jr NZ, @nextBank
	ret

@error:
	; Keep iflags
	in rIE
	push AF
	out rIE, IF_VBLANK
	out rIF, $00
	sleep

	push HL

	; Display error message
	ldp DE, strSramTestError
	gosub InitPopup

	; Set OAMs
	ld HL, $FE00
	ld (HL), $90 ; y
	inc HL
	ld (HL), $88 ; x
	inc HL
	ld (HL), B ; t = last bank
	inc HL
	ld (HL), $00 ; a
	inc HL

	pop BC
	ld (HL), $90 ; y
	inc HL
	ld (HL), $90 ; x
	inc HL
	ld (HL), B ; t = last addr hi
	inc HL
	ld (HL), $00 ; a
	inc HL

	ld (HL), $90 ; y
	inc HL
	ld (HL), $98 ; x
	inc HL
	ld (HL), C ; t = last addr lo
	inc HL
	ld (HL), $00 ; a

-	sleep
	gosub ReadInput
	bit _JP_A, A
	jr Z, -

	; Clear OAMs
	gosub ClearOAMS

	; Close message
	gosub ClosePopup

	; Restore iflags
	pop AF
	out rIE

	pop HL ; also exit previous routine
	ret

HashROM:
	ret

strSramTesting: text "Testing",DOTS
strSramTestError: text "Test failed at"
strSramTestSuccess: text "Test success"