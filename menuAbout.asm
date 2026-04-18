scrAbout:
	.db 7 ; lines
	;     ------------------
	text "About"
	text ""
	text "ROMUTILS v2"
	text ""
	text "Assembled"

	.db " on"
	.REPT 15-_DATE_.length
		.db " "
	.ENDR
	text _DATE_

	.db " at"
	.REPT 15-_TIME_.length
		.db " "
	.ENDR
	text _TIME_

About_Init:
	SetIFLAGS IF_VBLANK

	ldp HL, scrAbout
	ld DE, BG0
	gosub InitScreen
	gosub ClearOAMS

	ld A, $FF
	ld (JDOWN), A
	gosub ScreenOn

About_Loop:
	out rIF, 0
	in FRAMENUM
	inc A
	sleep
	out FRAMENUM
	gosub AnimateIdleIcon ; update "idle activity" icon

	gosub ReadInput
	and JP_A|JP_B
	jr Z, About_Loop

	RestoreIFLAGS
	pop AF
	pop AF
	goto Main
