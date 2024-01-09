#include <xc.inc>

extrn	DAC_Int_Hi_sine
global	change_signal, detect_notes

psect	udata_bank1 ; reserve data anywhere in RAM (here at 0x100)
Data_array: ds	0x80   ; reserve bytes for data

psect	data
ARRAY_LENGTH   equ 20
   
   
psect	code, abs

;freq: ds 1
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

;port C control
RCchange	equ	0	
RCsawtooth	equ	1
RCsine		equ	2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RCRecordON	equ	4
RCRecordOFF	equ	5
RCReplayON	equ	6
RCReplaystop	equ	7
RCClear		equ	3

;;;;;;;;;;;;;;;;;;;;;;;;;;;
delay_count:ds 1    ; reserve one byte for counter in the delay routine
freq_rollover: ds 1
delay_num:  ds 1
Recording:  ds 1
Replay: ds 1    

rst:	
	org	0x0000
	goto	main
	
hi_isr:
	org	0x0008
	bcf	INTCON, 2	;TMR0IF; reset interrupt
	goto	music_load
end_int:
	retfie	f		;return and reset interrupts
	    
main:
	org	0x0100
	bsf	TRISB, RBG	; Set PORTB as input
	bsf	TRISE, REE	; Set PORTE as input
	bsf	TRISJ, RJDs	; Set PORTJ as input
	bsf	TRISC, RCsawtooth  ; Set PORTC as input
	bcf	TRISF, 7
	bcf	TRISF, 6
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	BANKSEL 0x100
	clrf	0x100
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lfsr	0, Data_array		;0x100 as the start of storage for record mode
	movlw	0x01
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	0xFF
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	0xEA
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	bsf	INTCON,6	;PEIE	; Enable peripheral interrupts
        bsf	INTCON,7	;GIE	; Enable global interrupts
        
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
change_signal:
	btfsc	PORTC,RCsawtooth	;check if want to change signal
	goto	sawtooth
	btfsc	PORTC,RCsine
	call	DAC_Int_Hi_sine
	goto	change_signal		;loop to wait for choice of waveform
sawtooth:   ;sawtooth waveform branch
	lfsr	0, Data_array	;point to memory location 0x100
	movlw 	0x0
	movwf	TRISD, A	; Port D all outputs
	
	bra 	test
loop:
	movff 	0x06, PORTD	;counter codes
	incf 	0x06, W, A	;counter increment the value in 0x06
test:
	movwf	0x06, A	    ; Test for end of loop condition
	
	btfss	TRISF,6		;if replay is on, detect notes should not work
	call	detect_notes	;detect which note is played
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	btfsc	TRISF,7	    ;test if record mode is turned on
	call	record_condition    ;if yes go to recording branches
	btfsc	TRISF,6	    ;test if replay mode is turned on
	call	replay_condition
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	btfsc	TRISF,6	    ;test if replay mode is turned on
	movff	0x00, 0x03
	call	freq	    ;generates sawtooth wave by decrementing the value stored at 0x03
	btfsc	PORTC,RCchange	;check if want to change signal
	goto	change_signal			;return to choose signal
	btfsc	PORTC,RCRecordON    ;test if manual input to turn on record mode
	call	init_recording	    ;if yes, turn on the recording indicator
	btfsc	PORTC,RCRecordOFF   ;test if manul input to turn off record mode
	call	stop_recording	    ;if yes, turn off the recording indicator
	btfsc	PORTC,RCReplaystop  ;test if manual input to turn off replay mode
	call	stop_replay	    ;if yes, turn off the replaying indicator
	btfsc	PORTC,RCClear
	call	clear_recording
	btfsc	PORTC,RCReplayON	    ;test if manual input to turn on replay mode
	call	start_replay	    ;if yes, turn on the replaying indicator

	goto 	loop		    ; Re-run program from start

;Recording Branches;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_recording:
	bsf	PORTF,7	    ;set the recording indication pin high
	movlw	10000000B
	movwf	TRISF
	movlw	10000111B	; Set timer0 to 16-bit, prescaler:1/256
	movwf	T0CON, A
	lfsr	0, Data_array	;point to the right location
	clrf	TMR0L		;reset timer high word
	clrf	TMR0H		;reset timer low word
	bsf     T0CON, 7    ; Turn on Timer0
	return
stop_recording:
	bcf	PORTF,7	    ;clear the recording indication pin
	movlw	00000000B
	movwf	TRISF
	bcf     T0CON, 7 ; Turn off Timer0
	return
record_condition:
	movlw	0x00
	cpfsgt	FSR0L
	movff	0x0E,0x0F
	movlw	0x00
	cpfsgt	FSR0L
	movff	0x03, POSTINC0
	movlw	0x01
	cpfslt	FSR0L
	call	check_note
	return
check_note:
	movf	0x0E, W
	cpfseq	0x0F	    ; test if a different note is played
	call	recording	;when note is different, store time
	return
recording:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	movff	TMR0L,POSTINC0      ; Write the low word to the current location in the array
	movff	TMR0H,POSTINC0      ; Write the high word to the current location 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	movff	0x0E,0x0F	    ;move the note indication into 0x0F for comparison in the next round
	movff	0x03,POSTINC0	;move frequency to memory
	;;;;;;;;;;;;;;;;;;;reset and restart the timer for the next stage change
	clrf	TMR0L		;reset timer high word
	clrf	TMR0H		;reset timer low word
	return
;Replay Branches;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
replay_condition:
	movlw	0x00
	cpfsgt	FSR0L
	call	replayON    ;if yes go to replaying branches
	return
start_replay:
	bsf	PORTF,6	    ;set the replaying indication pin high
	movlw	01000000B
	movwf	TRISF
	clrf	0x0A
	clrf	0x0B
	lfsr	0, Data_array	;point to memory location 0x100
	return
stop_replay:
	bcf     INTCON, 5
	bcf	PORTF,6	    ;set the replaying indication pin high
	movlw	00000000B
	movwf	TRISF
	return
replayON:
	movff	0x00, 0x03	;move the pre-saved backup frequency value to 0x03 for this round of delay
	call	music_load  ;load next note played in memory
	return
music_load:
	bsf	INTCON,7	;GIE	; Enable global interrupts
	movff	INDF0,0x03		;move frequency number into 0x03
	movff	0x03,0x00		;move the frequency into 0x00 for backup use

	incf	FSR0L		;increment FSR0 low word
	btfsc	STATUS,2	;test if FSR0L incremented to 0xFF
	incf	FSR0H		;if overflowed, increment FSR0H
	;;;;;;;;;;;;;;;;
	movf	INDF0,W
	sublw	0xFF
	movwf	TMR0H
	;;;;;;;;;;;;;;;;
	incf	FSR0L		;same job as the previous one
	btfsc	STATUS,2	
	incf	FSR0H	
	;;;;;;;;;;;;;;;;
	movf	INDF0,W
	sublw	0xFF
	movwf	TMR0L
	;;;;;;;;;;;;;;;
	incf	FSR0L		;same job as the previous ones
	btfsc	STATUS,2	
	incf	FSR0H
	bsf     INTCON, 5    ;TMR0IE	imer0 overflow interrupt; Enable Timer0 overflow interrupt
	movlw	10000111B ;10000110B	; Set timer0 to 16-bit, prescaler:1/128
	movwf	T0CON, A
	return
;Clear Memory;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clear_recording:	
	lfsr	0, Data_array
clear:
	movlw	0x00
	movwf	POSTINC0
	movlw	0xFF
	cpfseq	FSR0L	
	bra	clear
	return
;NOTE Detection Branches;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
detect_notes:
	call	note_check
	return
note_check:
	;port B note check
	btfsc   PORTB,RBG	; Test if the button pin is clear (pressed)
        goto	NoteRBG		; If pressed, jump to button_pressed
	btfsc   PORTB,RBFs    
        goto	NoteRBFs
	btfsc   PORTB,RBF    
        goto	NoteRBF
	btfsc   PORTB,RBE    
        goto	NoteRBE
	btfsc   PORTB,RBDs    
        goto	NoteRBDs
	btfsc   PORTB,RBD    
        goto	NoteRBD
	btfsc   PORTB,RBCs    
        goto	NoteRBCs
        goto	NoteRBC	    	    
	;port F note check
	btfsc   PORTE,REB   
        goto	NoteREB
	btfsc   PORTE,REAs    
        goto	NoteREAs
	btfsc   PORTE,REA    
        goto	NoteREA
	btfsc   PORTE,REGs    
        goto	NoteREGs
	btfsc   PORTE,REG    
        goto	NoteREG
	btfsc   PORTE,REFs    
        goto	NoteREFs
	btfsc   PORTE,REF    
        goto	NoteREF
	btfsc   PORTE,REE    
        goto	NoteREE
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
	movlw	0x0C
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
	movlw	0x05
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
	movlw	0x04
	movwf	0x03, A
	movlw	0x01
	movwf	0x0E
	return
NoteRBG:
	movlw	0x04 
	movwf	0x03, A
	movlw	0x19
	movwf	0x0E
	return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
freq:
	decfsz	0x03
	bra freq
	return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
delay:	
	decfsz	0x09
	bra	delay
	return
end	rst
