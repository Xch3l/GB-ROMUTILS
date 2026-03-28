.DEFINE RTC_DH $0C
.DEFINE RTC_DL $0B
.DEFINE RTC_H  $0A
.DEFINE RTC_M  $09
.DEFINE RTC_S  $08

.DEFINE _RTC_CARRY 7
.DEFINE _RTC_HALT  6

.DEFINE RTC_CARRY  1<<_RTC_CARRY
.DEFINE RTC_HALT   1<<_RTC_HALT

.DEFINE MBC_ACCESS   $0000
.DEFINE MBC3_RAMBANK $4000
.DEFINE MBC3_LATCH   $6000

RTCMenu:
	.db 7
	dwp @vbl
	dwp @loop
	; labels
	dwp strRTCTitle
	dwp strRTCEnabled
	dwp strRTCOverflow
	dwp strRTCSeconds
	dwp strRTCMinutes
	dwp strRTCHours
	dwp strRTCDays
	dwp strReturn
	; callbacks
	dwp RTCEnabled
	dwp RTCOverflow
	dwp NopRetn; RTCSeconds
	dwp NopRetn; RTCMinutes
	dwp NopRetn; RTCHours
	dwp NopRetn; RTCDays
	dwp ReturnSubmenu

@vbl:
	ldp HL, RTCBuf
	ld DE, BG0+7
	ld B, 12
-	ldi A, (HL)
	ld (DE), A
	inc DE
	dec B
	jr NZ, -

	ldi A, (HL) ; HALT flag
	ld (BG0+$52), A

	ldi A, (HL) ; CARRY flag
	ld (BG0+$72), A

	ret

@loop:
	gosub RTCUnlock

	; Latch RTC
	ld HL, MBC3_LATCH
	xor A
	ld (HL), A
	inc A
	ld (HL), A

	; Read RTC
	ldp HL, RTCData
	ld B, 5
	ld C, $08
-	ld A, C
	ld (MBC3_RAMBANK), A
	ld A, ($A000)
	ldi (HL), A
	inc C
	dec B
	jr NZ, -

	gosub RTCLock

	; Convert days count
	ldp HL, RTC_Flag
	ldd A, (HL)
	and 1
	ld B, A
	ld C, (HL)
	gosub ToBCD

	ldp HL, RTCBuf_days
	ld A, B
	gosub PutHexLo
	ld A, C
	gosub PutHex

	; Convert Hours
	lda RTC_Hour
	ld C, A
	ld B, $00
	gosub ToBCD
	ldp HL, RTCBuf_hours
	ld A, C
	gosub PutHex

	; Convert Minutes
	lda RTC_Minute
	ld C, A
	ld B, $00
	gosub ToBCD
	ldp HL, RTCBuf_minutes
	ld A, C
	gosub PutHex

	; Convert Seconds
	lda RTC_Second
	ld C, A
	ld B, $00
	gosub ToBCD
	ldp HL, RTCBuf_seconds
	ld A, C
	gosub PutHex

	ldp HL, RTCBuf_flags
	ldp A, RTC_Flag ; get flags
	ld C, A

	; Get HALT state
	ld B, TICK_ICON
	bit _RTC_HALT, C
	jr Z, +
	dec B
+	ld A, B
	ldi (HL), A

	ld B, BOX_ICON
	bit _RTC_CARRY, C
	jr Z, +
	inc B
+	ld A, B
	ld (HL), A

	; Check RTC Halt flag
	ldp A, RTC_Flag
	bit _RTC_HALT, A
	jr NZ, @setRTC

@skipOptions:
	; Skip time registers if RTC is running
	ldp HL, MenuIndex
	ld A, (HL)
	dec A
	cp 5
	ret NC

	in JPRESS ; up or down?
	bit _JP_UP, A
	jr NZ, +
	ld (HL), $06
	ret
+	ld (HL), $00
	ret

@setRTC
	; Get current input
	in JDOWN
	ld B, A
	in JPRESS
	ld C, A
	ld A, JP_LEFT|JP_RIGHT
	ld D, 4
	gosub InputRepeat

	; Get current option
	lda MenuIndex
	ld B, A
	cp 6
	ret NC

	ldp HL, RTC_Second
	sub 2
	add L
	ld L, A
	jr NC, +
	inc H

+	bit _JP_LEFT, C
	jr Z, +
	ld D, -1
	dec (HL)
	jr @wrapValue
+	bit _JP_RIGHT, C
	ret Z
	ld D, 1
	inc (HL)

@wrapValue:
	ld A, B
	cp 5 ; check for "Set days"
	jr Z, @wrapDays
	cp 4 ; check for "Set hours"
	jr NZ, +
	ld BC, (RTC_H<<8)+24
	jr ++
+	ld BC, (RTC_M<<8)+60
	cp 2 ; check for "Set seconds"
	jr NZ, ++
	dec B ; RTC_S

++
	ld A, (HL)
	bit 7, A ; negative?
	jr Z, +
	dec C
	ld (HL), C
	jr @writeValue
+	cp C
	jr C, @writeValue
	ld (HL), 0

@writeValue:
	ld A, B
	gosub RTCUnlock
	ld A, (HL)
	ld ($A000), A
	goto RTCLock

@wrapDays:
	ld A, RTC_DL
	gosub RTCUnlock

	ldi A, (HL) ; A = lower byte of days; HL = flags
	ld ($A000), A ; write day value

	bit 7, D ; decreased value?
	jr Z, +
	cp $FF
	jr Z, ++
	goto RTCLock
+	and A
	gotonz RTCLock

++	; Toggle bit
	ld A, RTC_DH
	ld (MBC3_RAMBANK), A

	ld A, (HL)
	xor 1
	ld ($A000), A
	goto RTCLock

RTCEnabled:
	; Select DH/Flags register
	ld A, RTC_DH
	gosub RTCUnlock

	ld HL, $A000
	ld A, (HL)
	xor RTC_HALT
	ld (HL), A

	goto RTCLock

RTCOverflow:
	ld A, RTC_DH
	gosub RTCUnlock

	ld HL, $A000
	ld A, (HL)
	xor RTC_CARRY
	ld (HL), A

	goto RTCLock

RTCUnlock:
	ld (MBC3_RAMBANK), A ; select reg

	; Enable access
	ld A, $0A
	ld (MBC_ACCESS), A
	ret

RTCLock: ; Disable access
	xor A
	ld (MBC_ACCESS), A
	ret

RTCData:
	RTC_Second: .db "S"
	RTC_Minute: .db "M"
	RTC_Hour:   .db "H"
	RTC_Day:    .db "D"
	RTC_Flag:   .db "F"

RTCBuf:
	RTCBuf_days:    .db "--- "
	RTCBuf_hours:   .db "--:"
	RTCBuf_minutes: .db "--:"
	RTCBuf_seconds: .db "--"
	RTCBuf_flags:   .db "??" ; status
