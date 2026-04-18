; Line width:            "--------------"
strReturn:           text "Return"

; Main menu
strMainTitle:        text "Main menu" ; title
strMainViewHeader:   text "View Header"
strMainBackupROM:    text "Backup ROM"
strMainBackupSRAM:   text "Backup SRAM"
strMainRestoreSRAM:  text "Restore SRAM"
strMainCartOptions:  text "Cart options"
strMainTestIR:       text "Test IR"
strMainAbout:        text "About…"

; Cart Options Menu
strCartOptionsTitle: text "Cart options"
strViewRTC:          text "View RTC"
strTestRumble:       text "Test Rumble"
strTestSRAM:         text "Test SRAM"
strHashROM:          text "Hash ROM"

; RTC Menu
strRTCTitle:         text "RTC"
strRTCEnabled:       text "Enabled"
strRTCOverflow:      text "Overflow"
strRTCSeconds:       text "Set seconds"
strRTCMinutes:       text "Set minutes"
strRTCHours:         text "Set hours"
strRTCDays:          text "Set days"

; IR Menu
strIRMenuTitle:      text "IR Comms.Test"
strIRListen:         text "Listen"
strIRRecieve:        text "Receive"
strIRTransmit:       text "Transmit       < >"
strIRTimer:          text "Timer          < >"
strIRSpeed:          text "Divider          >"
strIRToggle:         text "Toggle"
strIRDIV:            .db "<256  <4 <16 <64"

; Rumble Menu
strRumbleTitle:      text "Rumble"
strRumStrength:      text "Strength"
strRumDuration:      text "Duration"

; Messages                 ------------------
strDumpingROM:       text $10,"Dumping ROM…"
strDumpingSRAM:      text $10,"Dumping SRAM…"
strRestoringSRAM:    text "Restoring SRAM…"
strCommsError:       text "Comms.error"
strCommsTimeout:     text "Comms.timed out"
strComplete:         text "Complete"
;strNoCart:           text "No cart inserted"
strNoSRAM:           text "No SRAM"
strInvalidSRAM:      text "Invalid SRAM byte"
strIRRecv:           text "Receiving…"
strIRXmit:           text "Transmitting…"
strNoRTC:            text "No MBC+RTC found"
strNotAvailable:     text "Not available"

; Screens
AGBHoldScreen:
	;[TODO] Compress this thing
	;    "....................------------"
	.asc "                                " ; 00
	.asc "     ••••••••••                 " ; 20
	.asc "   ••          ••               " ; 40
	.asc "  •   ••••••••   •              " ; 60
	.asc " •    ••••••••    •             " ; 80
	.asc " •  • ••••••••    •             " ; A0
	.asc " • •••••••••••  Ø •             " ; C0
	.asc " •  • •••••••• Ø  •             " ; E0
	.asc " •   .••••••••    •             " ; 00
	.asc "  •  .           •              " ; 20
	.asc "   •••        •••               " ; 40
	.asc "      ••••••••                  " ; 60
	.asc "                                " ; 80
	.asc "                                " ; A0
	.asc "  GBA on stand by…              " ; C0
	.asc "                                " ; E0
	.asc "  Hold A+B to exit",0
