IRMenu:
	.db 6
	dwp IRVBL
	dwp IRMenuLoop
	;labels
	dwp strIRMenuTitle
	dwp strIRRecieve
	dwp strIRTransmit
	dwp strIRTimer
	dwp strIRSpeed
	dwp strIRToggle
	dwp strReturn
	;callbacks
	dwp IRRecv
	dwp IRXmit
	dwp IRXmit
	dwp IRXmit
	dwp IRToggle
	dwp IRRetn

IRData:  .db $A5
IRDelay: .db $C0
IRSpeed: .db TIMER_4

IRVBL:
	; Get diode state
	in rIRP
	rra
	ld A, BOX_ICON
	adc $00
	ld (BG0+$D1), A

	; Display current divider
	lda IRSpeed
	and 3
	add A
	add A
	ld B, $00
	ld C, A
	ldp HL, strIRDIV
	add HL, BC
	ld B, 3
	ld DE, BG0+$AF
-	ldi A, (HL)
	ld (DE), A
	inc DE
	dec B
	jr NZ, -
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
	jr Z, @incDec
	inc HL ; IRSpeed
	cp 3
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
	SetIFLAGS IF_NONE

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

	RestoreIFLAGS
	ret

IRXmit:
	; Backup isource
	in rIE
	push AF

	; Enable timer
	ldp HL, IRDelay
	lda IRSpeed
	and 3
	or TIMER_ON
	out rTAC
	ldd A, (HL)
	out rTMA
	out rIF, $00
	out rIE, IF_TIMER

	ld BC, $0280 ; start bits; B = 2 bits, C = %10000000
	gosub IRSend

	ld C, (HL) ; data byte
	ld B, 8 ; bits
	gosub IRSend

	ld BC, $0180 ; stop bit(s)
	gosub IRSend

	RestoreIFLAGS
	ret

IRSend:
	out rIF, $00
	inc A ; A = 1
	rl C
	sleep
	out rIRP ; IR=on
	dec A
	jr NC, @zero

@one:
	out rIF
	sleep
	;out rIRP ; IR=off
	out rIF
	sleep
	out rIRP ; IR=off
	jr @next

@zero:
	out rIF
	sleep
	out rIRP ; IR=off
	out rIF
	sleep
	;out rIRP ; IR=off

@next:
	dec B
	jr NZ, IRSend
	ret

IRToggle:
	in rIRP
	xor $01
	out rIRP
	ret

IRRetn:
	out rSNDCTRL, $00 ; disable audio
	out rTAC ; disable timer
	out rIRP ; disable IR
	goto ReturnSubmenu
