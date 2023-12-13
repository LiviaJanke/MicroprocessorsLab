#include <xc.inc>

global	detect_notes


psect	detect_code, class = CODE

;port B notes
RBC	equ 0   
RBCs	equ 1
RBD	equ 2
RBDs	equ 3
RBE	equ 4
RBF	equ 5
RBFs	equ 6
RBG	equ 7

;port E notes
REB	equ 7
REAs	equ 6
REA	equ 5
REGs	equ 4
REG	equ 3
REFs	equ 2
REF	equ 1
REE	equ 0

;port J notes
RJDs	equ 7
RJD	equ 6
RJCs	equ 5
RJC	equ 4
RJB	equ 3
RJAs	equ 2
RJA	equ 1
RJGs	equ 0
    
    
;NOTE Detection Branches;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
detect_notes:
	;banksel TRISB    ; Select bank for BUTTON_PIN
	call	note_check
	return
note_check:
	;port B note check
	btfsc   PORTB,RBC    ; Test if the button pin is clear (pressed)
        goto	NoteRBC	    ; If pressed, jump to button_pressed
	btfsc   PORTB,RBCs    
        goto	NoteRBCs	    
	btfsc   PORTB,RBD    
        goto	NoteRBD	    
	btfsc   PORTB,RBDs    
        goto	NoteRBDs	    
	btfsc   PORTB,RBE    
        goto	NoteRBE	    
	btfsc   PORTB,RBF    
        goto	NoteRBF	    
	btfsc   PORTB,RBFs    
        goto	NoteRBFs	    
	btfsc   PORTB,RBG    
        goto	NoteRBG	    
	;port F note check
	btfsc   PORTE,REE    
        goto	NoteREE
	btfsc   PORTE,REF    
        goto	NoteREF
	btfsc   PORTE,REFs    
        goto	NoteREFs
	btfsc   PORTE,REG    
        goto	NoteREG
	btfsc   PORTE,REGs    
        goto	NoteREGs
	btfsc   PORTE,REA    
        goto	NoteREA
	btfsc   PORTE,REAs    
        goto	NoteREAs
	btfsc   PORTE,REB   
        goto	NoteREB
	;port J note check
	btfsc   PORTJ,RJDs   
        goto	NoteRJDs
	btfsc   PORTJ,RJD   
        goto	NoteRJD
	btfsc   PORTJ,RJCs    
        goto	NoteRJCs
	btfsc   PORTJ,RJC    
        goto	NoteRJC
	btfsc   PORTJ,RJB    
        goto	NoteRJB
	btfsc   PORTJ,RJAs    
        goto	NoteRJAs
	btfsc   PORTJ,RJA    
        goto	NoteRJA
	btfsc   PORTJ,RJGs    
        goto	NoteRJGs
	;if all NO, go to default
	goto	default
	return	
; NOTE Branches;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
default:
	movlw	0xFF
	movwf	0x03, A
	movlw	0x18
	movwf	0x0E
	return
;PORT J notes
NoteRJGs:
	movlw	0x28 
	movwf	0x03, A
	movlw	0x17
	movwf	0x0E
	return
NoteRJA:
	movlw	0x25 
	movwf	0x03, A
	movlw	0x16
	movwf	0x0E
	return
NoteRJAs:
	movlw	0x22 
	movwf	0x03, A
	movlw	0x15
	movwf	0x0E
	return
NoteRJB:
	movlw	0x1E 
	movwf	0x03, A
	movlw	0x14
	movwf	0x0E
	return
NoteRJC:
	movlw	0x1C
	movwf	0x03, A
	movlw	0x13
	movwf	0x0E
	return	
NoteRJCs:
	movlw	0x19 
	movwf	0x03, A
	movlw	0x12
	movwf	0x0E
	return	
NoteRJD:
	movlw	0x17 
	movwf	0x03, A
	movlw	0x11
	movwf	0x0E
	return
NoteRJDs:
	movlw	0x15 
	movwf	0x03, A
	movlw	0x10
	movwf	0x0E
	return
;PORT E notes
NoteREE:
	movlw	0x13 
	movwf	0x03, A
	movlw	0x0F
	movwf	0x0E
	return
NoteREF:
	movlw	0x11 
	movwf	0x03, A
	movlw	0x0E
	movwf	0x0E
	return
NoteREFs:
	movlw	0x0F 
	movwf	0x03, A
	movlw	0x0D
	movwf	0x0E
	return
NoteREG:
	movlw	0x0E 
	movwf	0x03, A
	movlw	0x0C
	movwf	0x0E
	return
NoteREGs:
	movlw	0x0D
	movwf	0x03, A
	movlw	0x0B
	movwf	0x0E
	return	
NoteREA:
	movlw	0x0B 
	movwf	0x03, A
	movlw	0x0A
	movwf	0x0E
	return	
NoteREAs:
	movlw	0x0A 
	movwf	0x03, A
	movlw	0x09
	movwf	0x0E
	return
NoteREB:
	movlw	0x09 
	movwf	0x03, A
	movlw	0x08
	movwf	0x0E
	return
;PORT B notes
NoteRBC:
	movlw	0x08 
	movwf	0x03, A
	movlw	0x07
	movwf	0x0E
	return
NoteRBCs:
	movlw	0x07 
	movwf	0x03, A
	movlw	0x06
	movwf	0x0E
	return
NoteRBD:
	movlw	0x07 
	movwf	0x03, A
	movlw	0x05
	movwf	0x0E
	return
NoteRBDs:
	movlw	0x06 
	movwf	0x03, A
	movlw	0x04
	movwf	0x0E
	return
NoteRBE:
	movlw	0x06
	movwf	0x03, A
	movlw	0x03
	movwf	0x0E
	return	
NoteRBF:
	movlw	0x05 
	movwf	0x03, A
	movlw	0x02
	movwf	0x0E
	return	
NoteRBFs:
	movlw	0x05
	movwf	0x03, A
	movlw	0x01
	movwf	0x0E
	return
NoteRBG:
	movlw	0x05 
	movwf	0x03, A
	movlw	0x19
	movwf	0x0E
	return


