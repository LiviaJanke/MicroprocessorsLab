#include <xc.inc>

extrn	DAC_Int_Hi_sine
extrn	detect_notes, note_check
global	change_signal

psect	udata_bank1 ; reserve data anywhere in RAM (here at 0x100)
Data_array: ds	0x80   ; reserve bytes for data

psect	data
ARRAY_LENGTH   equ 20
   
   
psect	code, abs

RBG	equ 7	
REE	equ 0
RJDs	equ 7	
	
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
	bsf	TRISE, REE
	bsf	TRISJ, RJDs	; Set PORTH as input
	bsf	TRISC, RCsawtooth
	bcf	TRISF, 7
	bcf	TRISF, 6
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	movlw	0x55
	movwf	0x02
	movlw	0x01
	movwf	0x09
	BANKSEL 0x100
	clrf	0x100
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lfsr	0, Data_array 
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
	call	recordON    ;if yes go to recording branches
	btfsc	TRISF,6	    ;test if replay mode is turned on
	call	replay_condition
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	btfsc	TRISF,6	    ;test if replay mode is turned on
	movff	0x00, 0x03
	call	freq	    ;frequency variable
	btfsc	PORTC,RCchange	;check if want to change signal
	goto	change_signal			;return to choose signal
	btfsc	PORTC,RCRecordON    ;test if manual input to turn on record mode
	call	start_recording	    ;if yes, turn on the recording indicator
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
start_recording:
	bsf	PORTF,7	    ;set the recording indication pin high
	movlw	10000000B
	movwf	TRISF
	movlw	10000111B	; Set timer0 to 16-bit, prescaler:1/256
	movwf	T0CON, A
	lfsr	0, Data_array	;point to the right location
	clrf	TMR0L		;reset timer high word
	clrf	TMR0H		;reset timer low word
	bsf     T0CON, 7 ; Turn on Timer0
	return
	
stop_recording:
	bcf	PORTF,7	    ;clear the recording indication pin
	movlw	00000000B
	movwf	TRISF
	bcf     T0CON, 7 ; Turn off Timer0
	return
	
recordON:
	movlw	0x00
	cpfsgt	FSR0L
	movff	0x0E,0x0F
	movlw	0x00
	cpfsgt	FSR0L
	movff	0x03, POSTINC0
	movlw	0x01
	cpfslt	FSR0L
	call	after_note
	return
	
after_note:
	movf	0x0E, W
	cpfseq	0x0F	    ; test if a different note is played
	call	recording	;when note is different, store time
	return
	
recording:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	movff	TMR0L,POSTINC0      ; Write the high word to the current location in the array
	movff	TMR0H,POSTINC0      ; Write the low word to the current location 
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
	movlw	10000110B	; Set timer0 to 16-bit, prescaler:1/256
	movwf	T0CON, A
	return

duration:
	;movff	0x00, 0x03	;move the pre-saved backup frequency value to 0x03 for this round of delay
	dcfsnz	0x0B		;decrement low word, if 0, proceed to decrement of 0x0A
	call	multi_delay	;derement of high word 0x0A
	return

multi_delay:
	tstfsz	0x0A		;test if 0x0A is 0, if is, the value has reached 0x0000, so return to music load
	call	more_delay	;if 0x0A is not 0, decrement 0x0A
	return

more_delay:
	decf	0x0A
	decf	0x0B
	return

prescaler:
	movlw	0x02		;frequency modulation for replay mode
	movwf	0x09
	movff	0x00, 0x03	;move the pre-saved backup frequency value to 0x03 for this round of delay
	decf	0x02
	btfsc	STATUS,2
	goto	replayON
	return

condition:
	movlw	0x10
	movwf	0x02
	incf	0x01
	movlw	0x01
	cpfslt	0x01
	goto	replayON
	return

skip:
	movlw	0xFF
	cpfseq	0x03
	call	freq
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
