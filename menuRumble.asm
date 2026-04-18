.DEFINE MBC5_RAMBANK $4000

RumbleMenu:
	.db 3
	dwp @vbl
	dwp @loop
	dwp strRumbleTitle ; title

	; labels
	dwp strRumStrength
	dwp strRumDuration
	dwp strReturn
	; callbacks
	dwp StartRumble
	dwp StartRumble
	dwp RumReturn

@vbl:
;;	ldp HL, RumbleTimer
;;	xor A
;;	cp (HL)
;;	jr NZ, @tick
;;	xor A
;;	jr _f
;;
;;@tick:
;;	;in FRAMENUM
;;	;and 3
;;	;jr NZ, +
;;	dec (HL)
;;
;;+	ldp HL, RumbleStrength
;;	ldi A, (HL)
;;	ld B, $00
;;	inc (HL)
;;	cp (HL)
;;	jr NC, +
;;	set 3, B
;;+	ld A, B
;;
;;__
;;	ld (MBC5_RAMBANK), A
	ret

@loop:
	in JDOWN
	ld B, A
	in JPRESS
	ld C, A
	ld A, JP_LEFT|JP_RIGHT
	ld D, 3
	gosub InputRepeat

	ldp HL, RumbleStrength
	lda MenuIndex
	cp 2
	jr NC, _f
	and A
	jr Z, +
	inc HL

+	; Test inputs
	bit _JP_LEFT, C
	jr Z, +
	dec (HL)
	jr _f
+	bit _JP_RIGHT, C
	jr Z, _f
	inc (HL)

__
	; Display values
	ld DE, OAMTABLE
	ldp HL, @oams
	ld B, 8
-	ldi A, (HL)
	ld (DE), A
	inc DE
	dec B
	jr NZ, -

	ldp HL, RumbleStrength
	ldi A, (HL)
	ld (OAMTABLE+2), A

	ldi A, (HL)
	ld (OAMTABLE+6), A
	ret

@oams:
	.db $20, $90, $00, $00
	.db $28, $90, $00, $00

RumbleStrength: .db 32
RumbleDuration: .db 60 ; frames

StartRumble:
	; Get values
	ldp HL, RumbleStrength
	ld E, (HL) ; strength
	inc HL
	ld D, (HL) ; duration
	ld H, $00 ; PWM counter
	ld B, H

	; Setup timer
	out rTMA, $80
	out rTAC, TIMER_ON|1

	; Select interrupts
	in rIE
	push AF
	out rIE, IF_VBLANK|IF_TIMER

-	ld A, B ; set vibration
	ld (MBC5_RAMBANK), A

	out rIF, 0 ; wait interrupt
	sleep
	in rIF
	ld L, A
	bit _IF_TIMER, L
	jr Z, @checkVbl

	; Increase timer
	set 3, B
	inc H
	ld A, H
	cp E
	jr C, +
	res 3, B
+

@checkVbl:
	bit _IF_VBLANK, L
	jr Z, -

	; Decrease duration (frames left)
	dec D
	jr NZ, -

	; Stop vibration
	xor A
	ld (MBC5_RAMBANK), A
	out rTAC ; stop timer

	; Restore interrupts
	RestoreIFLAGS
	ret

RumReturn:
	xor A
	ld (MBC5_RAMBANK), A
	goto ReturnSubmenu
