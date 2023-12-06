psect	dac_code, class=CODE
#include <xc.inc>
    
extrn	change_signal, detect_notes
global	DAC_Setup_square, DAC_Int_Hi_square

psect	data
    
psect	udata_acs
counter1: ds 1
counter2: ds 1
freq_rollover: ds 1
freq_replay: ds 1
;port C control
;RCRecordstart	equ	0
;RCRecordstop	equ	1
;RCReplay	equ	2
;RCClear	equ	3
RCchange	equ	0	
RCsawtooth	equ	1
RCsine		equ	2
RCsquare	equ	3
    
    
    
psect	dac_code, class=CODE


DAC_Int_Hi_square:	; Outputs Square pulse (Uncomment to output sine with DAC)
	;movlw	0xFF
	movwf	freq_rollover, A
	;btfss	TMR0IF		; check that this is timer0 interrupt
	;bra	Record		; Branch to Recording if timer1 interrupt    
	movlw	0xFF
	movwf	TMR0H, A	
	movff	freq_rollover, TMR0L, A	; assign to the lower 8 bits
	tstfsz	freq_rollover, A
	;bcf	LATH, 0, A	; control signal
	call	Squarewave
	;dcfsnz	counter1, A	  
	;call	Load_waveform ; Load Lookup table waveform
	;tblrd*+			; move along table
	;movff	TABLAT, LATD, A ; move value from table to port J
	call	detect_notes
	call	delay
	bsf	LATH, 0, A
	bcf	TMR0IF		; clear interrupt flag
	;retfie	f		; fast return from interrupt
	btfsc	PORTC,RCchange	;check if want to change signal
	goto	change_signal	;return to choose signal
	goto	DAC_Int_Hi_square

Squarewave:
	tstfsz	LATD, A
	decfsz	LATD, A
	incf	LATD, A

	return
	
;Record:
	;btfsc	Recording, 0, A	    ; Check Recording mode enabled
	;call	Store_note
	;btfsc	Replay, 0, A	    ; Check Replay mode enabled
	;movff	POSTINC0, freq_replay, A    
	;bcf	TMR1IF		; clear interrupt flag
	;retfie	f		; fast return from interrupt
	;return
	
;Store_note: ;Store freq_rollover into data memory
;	movlw	0x0E		
;	cpfslt	FSR0H, A	; rollover when FSR0 points to bank 15
;	lfsr	0, 0x200        ; Start memory storage at Bank 2, use pointer 0
;	incf	LATH, A
;	movff	freq_rollover, POSTINC0, A
;	return
	
;Clear_Recording:
;	lfsr	0, 0x200
Next:				
	clrf	POSTINC0, A	    ;Clear storage
	movlw	0x0E
	cpfsgt	FSR0H, A  
	bra	Next
	movlw	0
	movwf	LATH, A
	
	return
	
DAC_Setup_square:
	clrf	TRISJ, A	; Set PORTD as all outputs
	clrf	LATJ, A		; Clear PORTD outputs
	clrf	TRISH, A
	clrf	LATH, A
	movlw	10000111B	; Set timer0 to 16-bit, 42.5kHz
	movwf	T0CON, A	
	bsf	TMR0IE		; Enable timer0 interrupt
	
	movlw	00110111B	; Set timer1 to 16-bit, 2MHz
	movwf	T1CON, A
	bsf	TMR1IE
	bsf	PEIE
	
	bsf	GIE		; Enable all interrupts
	
	;bcf	CFGS		; set up table
	;bsf	EEPGD
	;call	Load_waveform
	return
	
	
delay:
	decfsz	0x03
	bra delay
	return
	end





