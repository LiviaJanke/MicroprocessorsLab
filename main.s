#include <xc.inc>


psect	code, abs

freq: ds 1
;port B notes
RBC	equ 0   ;0x22 for C note
RBCs	equ 1
RBD	equ 2
RBDs	equ 3
RBE	equ 4
RBF	equ 5
RBFs	equ 6
RBG	equ 7

;port F notes
RFB	equ 7
RFAs	equ 6
RFA	equ 5
RFGs	equ 4
RFG	equ 3
RFFs	equ 2
RFF	equ 1
RFE1	equ 0

;port H notes
RHDs	equ 7
RHD	equ 6
RHCs	equ 5
RHC	equ 4
RHB	equ 3
RHAs	equ 2
RHA	equ 1
RHGs	equ 0
;RHG


	    
	    
	    
main:
	org	0x0
;	goto	start
	bsf     TRISB, RBC	; Set PORTB as input
	bsf	TRISF, RFB	; Set PORTF as input
	bsf	TRISH, RHDs	; Set PORTH as input
	;banksel TRISB         ; Select bank for TRISB register
        
	org	0x100		    ; Main code starts here at address 0x100
start:
	movlw 	0x0
	movwf	TRISD, A	; Port D all outputs
	
	;setf	TRISB, A
	;clrf	TRISB
;	CLRF	PORTJ	; Initialize PORTJ by
			; clearing output latches    
;	CLRF	LATJ	; Alternate method
			; to clear output latches
;	MOVLW	0CFh
	;movlw	0x0
	;movwf	TRISJ, A
;	bcf	PORTJ, 1 ,0
	
	
	bra 	test
loop:
	call	detect_notes
	movff 	0x06, PORTD
	incf 	0x06, W, A
test:
	movwf	0x06, A	    ; Test for end of loop condition
	movlw 	0xFF	    ; The count down max
	cpfsgt 	0x06, A
	;call	detect_notes
	;call	freq_change ;input the frequency number
	call	delay	    
	bra 	loop		    ; Not yet finished goto start of loop again
	;movff 	0x06, PORTJ
;	bsf	PORTJ, 1, 0
	goto 	0x0		    ; Re-run program from start

	
detect_notes:
	;banksel TRISB    ; Select bank for BUTTON_PIN
	call	note_check
        ;btfsc   PORTB,ButtonC    ; Test if the button pin is clear (pressed)
        ;goto	NoteC	    ; If pressed, jump to button_pressed
        ;movff	0x22, freq
	;goto    default           ; Otherwise, continue looping
	return
note_check:
	btfsc   PORTB,RBC    ; Test if the button pin is clear (pressed)
        goto	NoteRBC	    ; If pressed, jump to button_pressed
	btfsc   PORTB,RBCs    ; Test if the button pin is clear (pressed)
        goto	NoteRBCs	    ; If pressed, jump to button_pressed
	btfsc   PORTB,RBD    ; Test if the button pin is clear (pressed)
        goto	NoteRBD	    ; If pressed, jump to button_pressed
	btfsc   PORTB,RBDs    ; Test if the button pin is clear (pressed)
        goto	NoteRBDs	    ; If pressed, jump to button_pressed
	btfsc   PORTB,RBE    ; Test if the button pin is clear (pressed)
        goto	NoteRBE	    ; If pressed, jump to button_pressed
	btfsc   PORTB,RBF    ; Test if the button pin is clear (pressed)
        goto	NoteRBF	    ; If pressed, jump to button_pressed
	btfsc   PORTB,RBFs    ; Test if the button pin is clear (pressed)
        goto	NoteRBFs	    ; If pressed, jump to button_pressed
	btfsc   PORTB,RBG    ; Test if the button pin is clear (pressed)
        goto	NoteRBG	    ; If pressed, jump to button_pressed
	goto	default
	return
default:
	movlw	0xFF
	movwf	0x03
	return

freq_change:
	movlw	freq
	movwf	0x03, A
	return

NoteRBC:
	movlw	0x20 
	movwf	0x03, A
	return
NoteRBCs:
	movlw	0x1D 
	movwf	0x03, A
	return
NoteRBD:
	movlw	0x1A 
	movwf	0x03, A
	return
NoteRBDs:
	movlw	0x17 
	movwf	0x03, A
	return
NoteRBE:
	movlw	0x14 
	movwf	0x03, A
	return	
NoteRBF:
	movlw	0x11 
	movwf	0x03, A
	return	
NoteRBFs:
	movlw	0x0E 
	movwf	0x03, A
	return
NoteRBG:
	movlw	0x0C 
	movwf	0x03, A
	return
	
delay:
	decfsz	0x03
	bra delay
	return

	
	end	main
