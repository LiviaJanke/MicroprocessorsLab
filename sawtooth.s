#include <xc.inc>

extrn	DAC_Int_Hi_sine, DAC_Int_Hi_square
global	change_signal, detect_notes
	
psect	code, abs

;freq: ds 1
;port B notes
RBC	equ 0   ;0x22 for C note
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

;port C control
;RCRecordstart	equ	0
;RCRecordstop	equ	1
;RCReplay	equ	2
;RCClear	equ	3
RCchange	equ	0	
RCsawtooth	equ	1
RCsine		equ	2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RCRecordON	equ	4
RCRecordOFF	equ	5
RCReplay	equ	3

;;;;;;;;;;;;;;;;;;;;;;;;;;;
delay_count:ds 1    ; reserve one byte for counter in the delay routine
freq_rollover: ds 1
delay_num:  ds 1
Recording:  ds 1
Replay: ds 1
seq_array: ds 120
    
note_val equ 0x04   
	    
	    
main:
	org	0x0
	;org 0x08
	;retfie
	;org 0x18
	;retfie
	bsf	TRISB, RBG	; Set PORTB as input
	bsf	TRISE, REE
	bsf	TRISJ, RJDs	; Set PORTH as input
	bsf	TRISC, RCsawtooth
	
	;bsf	TRISC,2,A ; configure CCP1 pin for input
	;movlw	0x81 ; use Timer1 as the time base
	;movwf	T3CON,A ; of CCP1 capture
	;bcf	CCP1IE,A ; disable CCP1 capture interrupt
	;movlw	0x81 ; enable Timer1, prescaler set to 1,
	;movwf	T1CON,A ; 16-bit, y use instruction cycle clock
	;movlw	0x03 ; set CCP1 to capture on every edge
	;movwf	CCP1CON,A ; "
	;bcf	CCP1IF,A ; clear the CCP1IF flag

	;banksel TRISB         ; Select bank for TRISB register
        bsf     TMR0IE ; Enable Timer0 overflow interrupt
        bsf	GIE    ; Enable global interrupts
	movlw	10000111B	; Set timer0 to 16-bit, 42.5kHz
	movwf	T0CON, A
	clrf    TMR0          ; Clear Timer0
        bsf     T0CON, 7 ; Turn on Timer0
	org	0x100		    ; Main code starts here at address 0x100
	
change_signal:
	;btfsc	PORTC,RCsawtooth	;check if want to change signal
	goto	sawtooth
	;btfsc	PORTC,RCsine
	;call	DAC_Int_Hi_sine
	;btfsc	PORTC,RCsquare
	;call	DAC_Int_Hi_square
	;goto	change_signal			;loop
	
;sine:
	
sawtooth:
	

	
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
	
	;movf    TMR0, W       ; Read Timer0 value
	;incf    button_duration, W ; Increment the memory location for the next duration
	;movwf   button_duration          ; Store the duration in the current memory location
	

	;bcf     T0CON, 7
        ;movwf   0x08 ; Store the duration
	;call	change_sawtooth
	
	;btfsc	PORTC,RCRecordON

	;call	store_sawtooth
	movff 	0x06, PORTD
	incf 	0x06, W, A
test:
	movwf	0x06, A	    ; Test for end of loop condition
	movlw 	0xFF	    ; The count down max
	cpfsgt 	0x06, A
	call	detect_notes
	;movwf	0xFFF
	cpfseq	0x0F	; compare file register to previously played note
	call	record_time	;when note is different, store time
	movwf	0x0F
	;btfss	CCP1IF,A ; g wait for the first edge to arrive
	
	call	delay	 
	btfsc	PORTC,RCchange	;check if want to change signal
	goto	change_signal			;return to choose signal
	call	hugedelay
	call	deaddelay
	;call	deaddelay
	
	
	bra 	loop		    ; Not yet finished goto start of loop again
	;movff 	0x06, PORTJ
;	bsf	PORTJ, 1, 0
	
	goto 	0x0		    ; Re-run program from start

	
detect_notes:
	;banksel TRISB    ; Select bank for BUTTON_PIN
	call	note_check
	return
record_time:
	;movff	CCPR1H,PRODH ; save the first edge
	;movff	CCPR1L,PRODL
	;;;;;;;;;;;;;;;;;;;;;;;;;;
	movff   TMR0H, PRODH       ; Read Timer0 value
	movff	TMR0L, PRODL
	;incf    button_duration, W ; Increment the memory location for the next duration
	;movwf   button_duration          ; Store the duration in the current memory location
	; need to store contents of 0x03 (the frequency corresponding to the note) before decrementing to store the note
	;movlw	note_val
	
	
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


;freq_change:
;	movlw	freq
;	movwf	0x03, A
;	return

	
	
; NOTE Branches;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
default:
	movlw	0xFF
	movwf	0x03
	movlw	0x02
	return
;PORT J notes
NoteRJGs:
	movlw	0x45 
	movwf	0x03, A
	return
NoteRJA:
	movlw	0x40 
	movwf	0x03, A
	return
NoteRJAs:
	movlw	0x3B 
	movwf	0x03, A
	return
NoteRJB:
	movlw	0x38 
	movwf	0x03, A
	return
NoteRJC:
	movlw	0x36
	movwf	0x03, A
	return	
NoteRJCs:
	movlw	0x32 
	movwf	0x03, A
	return	
NoteRJD:
	movlw	0x2F 
	movwf	0x03, A
	return
NoteRJDs:
	movlw	0x2D 
	movwf	0x03, A
	return
;PORT E notes
NoteREE:
	movlw	0x30 
	movwf	0x03, A
	return
NoteREF:
	movlw	0x2B 
	movwf	0x03, A
	return
NoteREFs:
	movlw	0x26 
	movwf	0x03, A
	return
NoteREG:
	movlw	0x23 
	movwf	0x03, A
	return
NoteREGs:
	movlw	0x1E
	movwf	0x03, A
	return	
NoteREA:
	movlw	0x1A 
	movwf	0x03, A
	return	
NoteREAs:
	movlw	0x16 
	movwf	0x03, A
	return
NoteREB:
	movlw	0x13 
	movwf	0x03, A
	return
;PORT B notes
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
delay:
	decfsz	0x03
	bra delay
	return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
bigdelay:
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	return
hugedelay:
	call	bigdelay
	call	bigdelay
	call	bigdelay
	call	bigdelay
	call	bigdelay
	call	bigdelay
	call	bigdelay
	return
deaddelay:
	call	hugedelay
	call	hugedelay
	call	hugedelay
	call	hugedelay
	call	hugedelay
	call	hugedelay
	call	hugedelay
	call	hugedelay
	call	hugedelay
	call	hugedelay
	return
	
;store_sawtooth:
;	clrf    TMR0          ; Clear Timer0
;       bsf     T0CON, 7 ; Turn on Timer0
;	return
	
	
;change_sawtooth:
;	movf    TMR0, W       ; Read Timer0 value
;        movwf   0x08 ; Store the duration
;	bcf     T0CON, 7
;	return
	
	
end	sawtooth