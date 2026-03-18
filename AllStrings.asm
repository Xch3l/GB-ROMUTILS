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
strMainAbout:        text "About",DOTS

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
strIRRecieve:        text "Receive"
strIRTransmit:       text "Transmit       < >"
strIRTimer:          text "Timer          < >"
strIRToggle:         text "Toggle"
strIRPWM:            text "Pulse"

; Messages                 ------------------
strDumpingROM:       text $10,"Dumping ROM",DOTS
strDumpingSRAM:      text $10,"Dumping SRAM",DOTS
strRestoringSRAM:    text "Restoring SRAM",DOTS
strCommsError:       text "Comms.error"
strCommsTimeout:     text "Comms.timed out"
strComplete:         text "Complete"
;strNoCart:           text "No cart inserted"
strNoSRAM:           text "No SRAM"
strInvalidSRAM:      text "Invalid SRAM byte"
strIRRecv:           text "Receiving",DOTS
strIRXmit:           text "Transmitting",DOTS
strNoRTC:            text "No MBC+RTC found"

; 
AGBHoldScreen:
	;   "....................------------"
	.db "                                " ; 00
	.db "     										                 " ; 20
	.db "   		          		               " ; 40
	.db "  	   								   	              " ; 60
	.db " 	    								    	             " ; 80
	.db " 	  	 								    	             " ; A0
	.db " 	 											  ", BOX_ICON, " 	             " ; C0
	.db " 	  	 								 ", BOX_ICON, "  	             " ; E0
	.db " 	   .								    	             " ; 00
	.db "  	  .           	              " ; 20
	.db "   			        			               " ; 40
	.db "      								                  " ; 60
	.db "                                " ; 80
	.db "                                " ; A0
	.db "   GBA on standby               " ; C0
	.db "                                " ; E0
	.db "  Hold A+B to exit",0

; About screen

