scrAbout:
	.db 7 ; lines
	;     ------------------
	text "About"
	text ""
	text "ROMUTILS v2"
	text ""
	text "Assembled"
	text " on ",_DATE_
	text " at ",_TIME_

About_Init:
	ldp HL, scrAbout
	ld DE, BG0
	gosub InitScreen
	gosub ClearOAMS

	ld A, $FF
	ld (JDOWN), A
	gosub ScreenOn

About_Loop:
	sleep
	gosub ReadInput
	and JP_A|JP_B
	jr Z, About_Loop

	pop AF
	pop AF
	goto Main
