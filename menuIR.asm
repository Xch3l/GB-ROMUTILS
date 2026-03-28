IRMenu:
	.db 7
	dwp IRVBL
	dwp IRMenuLoop
	;labels
	dwp strIRMenuTitle
	dwp strIRListen
	dwp strIRRecieve
	dwp strIRTransmit
	dwp strIRTimer
	dwp strIRSpeed
	dwp strIRToggle
	dwp strReturn
	;callbacks
	dwp IRListen
	dwp MenuNotAvailable; IRRecv
	dwp IRXmit
	dwp IRXmit
	dwp IRXmit
	dwp IRToggle
	dwp IRRetn

IRData:  .db $55
IRDelay: .db $80
IRSpeed: .db TIMER_4

IRVBL:
	; Get diode state
	in rIRP
	rra
	ld A, BOX_ICON
	adc $00
	ld (BG0+$F1), A

	; Display current divider
	lda IRSpeed
	and 3
	add A
	add A
	ld B, $00
	ld C, A
	ldp HL, strIRDIV
	add HL, BC
	ld B, 4
	ld DE, BG0+$CE
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
	ld (HL), $30 ; y
	inc HL
	ld (HL), $90 ; x
	inc HL
	ldi (HL), A  ; t
	ld (HL), $00 ; a
	inc HL

	lda IRDelay
	ld (HL), $38 ; y
	inc HL
	ld (HL), $90 ; x
	inc HL
	ldi (HL), A  ; t
	ld (HL), $00 ; a

	in JDOWN
	ld B, A
	in JPRESS
	ld C, A
	ld A, JP_LEFT|JP_RIGHT
	ld D, 3
	gosub InputRepeat

	ldp HL, IRData
	lda MenuIndex
	cp 2
	jr Z, @incDec
	inc HL ; IRDelay
	cp 3
	jr Z, @incDec
	inc HL ; IRSpeed
	cp 4
	ret NZ

@incDec:
	bit _JP_LEFT, C
	jr NZ, @decValue
	bit _JP_RIGHT, C
	jr NZ, @incValue
	ret

@incValue:
	inc (HL)
	ret

@decValue:
	dec (HL)
	ret

IRListen:
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

	ld BC, $8002 ; start bits; B = data, C = bit count
	gosub IRSend

	ld B, (HL)   ; data byte
	ld C, 8      ; bit count
	gosub IRSend

	ld BC, $8002 ; stop bit(s)
	gosub IRSend

	RestoreIFLAGS
	ret

IRSend:
	out rIF, 0
	inc A ; A = 1
	rl B
	sleep
	out rIRP ; IR = ON
	jr NC, @zero

@one:
	out rIF, 0
	sleep

	out rIF
	sleep
	out rIRP ; IR = OFF
	jr @next

@zero:
	out rIF, 0
	sleep
	out rIRP ; IR = OFF

	out rIF
	sleep

@next:
	dec C
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
	out rIRP ; turn off IR
	goto ReturnSubmenu
