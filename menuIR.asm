IRMenu:
	.db 6
	dwp IRVBL
	dwp IRMenuLoop
	;labels
	dwp strIRMenuTitle
	dwp strIRRecieve
	dwp strIRTransmit
	dwp strIRTimer
	dwp strIRToggle
	dwp strIRPWM
	dwp strReturn
	;callbacks
	dwp IRRecv
	dwp IRXmit
	dwp IRXmit
	dwp IRToggle
	dwp IRPWM
	dwp IRRetn

IRVBL:
	in rIRP
	rra
	ld A, BOX_ICON
	adc $00
	ld (BG0+$B1), A
	ret

IRMenuLoop:
	; Set sprite
	ld HL, OAMTABLE
	lda IRData
	ld (HL), $28 ; y
	inc HL
	ld (HL), $90 ; x
	inc HL
	ldi (HL), A  ; t
	ld (HL), $00 ; a
	inc HL

	lda IRDelay
	ld (HL), $30 ; y
	inc HL
	ld (HL), $90 ; x
	inc HL
	ldi (HL), A  ; t
	ld (HL), $00 ; a

	ldp HL, IRData
	lda MenuIndex
	cp 1
	jr Z, @incDec
	inc HL ; IRDelay
	cp 2
	ret NZ

@incDec:
	in JPRESS
	bit _JP_LEFT, A
	jr NZ, @decValue
	bit _JP_RIGHT, A
	jr NZ, @incValue
	ret

@incValue:
	inc (HL)
	ret

@decValue:
	dec (HL)
	ret

IRData:  .db $55
IRDelay: .db $DE

IRRecv:
	ldp DE, strIRRecv
	gosub InitPopup

	; Enable audio
	out rSNDCTRL, $80
	out rSNDOUT, TONE1
	out $FF10, $00 ; Sweep
	out $FF11, $01 ; Duty+Length
	out $FF12, $F8 ; Volume
	out $FF13, $00 ; Freq. lo
	out $FF14, $83 ; Freq. hi

	; Disable interrupts
	in rIE
	push AF
	out rIE, $00

	; Set timer
	ld DE, $0000
	ld C, $04
	out rIRP, $C0 ; enable IR for reading

@loop:
	in rIRP
	ld B, A
	xor A
	bit 1, B
	jr NZ, +
	ld A, $77
+	out rMVOL
	in rSTAT ; check for VBlank
	and 3
	cp 2
	jr NC, @decCounter

	; in VBlank
	ld A, BOX_ICON
	bit 1, B
	jr NZ, +
	inc A
+	ld (BG1+$32), A

@decCounter:
	dec DE
	ld A, D
	or E
	jr NZ, @loop
	dec C
	jr NZ, @loop

	; Done reading
	out rSNDCTRL, $00 ; disable audio
	out rIRP ; disable IR
	gosub ClosePopup

	out rIF, $00
	pop AF
	out rIE
	ret

IRXmit:
	; Backup isource
	in rIE
	push AF

	; Enable timer
	ldp HL, IRDelay
	out rTAC, TIMER_ON|TIMER_4
	ldd A, (HL)
	out rTMA
	out rIF, $00
	out rIE, IF_TIMER

	ld C, $80
	ld B, 2 ; bits
	gosub @irSend
	ld C, (HL)
	ld B, 8 ; bits
	gosub @irSend

	; Transmit complete
	out rIF, $00
	sleep
	out rIRP ; disable IR

	; Restore isource
	out rIF, $00
	pop AF
	out rIE
	ret

@irSend:
	out rIF, $00
	sleep
	rl C
	rla
	out rIRP
	dec B
	jr NZ, @irSend
	ret

IRToggle:
	in rIRP
	xor $01
	out rIRP
	ret

IRPWM:
	ret

IRRetn:
	out rSNDCTRL, $00 ; disable audio
	out rTAC ; disable timer
	out rIRP ; disable IR
	goto ReturnSubmenu
