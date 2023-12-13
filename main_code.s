#include <xc.inc>

extrn	detect_notes
extrn	stop_recording, recordON
extrn	stop_replay, replayON, music_load
extrn	delay, bigdelay, hugedelay, deaddelay	      
extrn	Saw_wave, Sine_wave
    
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
RCRecordON	equ	4
RCRecordOFF	equ	5
RCReplayON	equ	6
RCReplaystop	equ	7
RCClear		equ	3


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
	btfss	INTCON, 2	;TMR0IF
	goto	end_int
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
	
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	movlw	0x55
	movwf	0x02
	BANKSEL 0x100
	clrf	0x100

	lfsr	0, Data_array 
	movlw	0x01
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	0xFF
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	0xEA
	movwf	TBLPTRL, A		; load low byte to TBLPTRL

	bsf     INTCON, 5    ;TMR0IE		; Enable Timer0 overflow interrupt
	bsf	INTCON2, 2	; TMR0IP
	bsf	INTCON, 6	;PEIE	; Enable peripheral interrupts
        bsf	INTCON, 7	;GIE	; Enable global interrupts

	
change_signal:
	
	BANKSEL 0x100 
	movlw	0x03
	movwf	0x100
	movlw	0xFF
	movwf	0x101
	movlw	0xFA
	movwf	0x102
	movlw	0x02
	movwf	0x103
	movlw	0x01
	movwf	0x104
	movlw	0x01
	movwf	0x105
	
	goto	sawtooth

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
	
	movlw	0x00
	cpfsgt	FSR0L
	call	replayON    ;if yes go to replaying branches
	
	;call	freq	    ;frequency variable
	
	btfsc	PORTC, RCsawtooth
	call	Saw_wave
	
	btfsc	PORTC, RCsine
	call	Sine_wave
	
	
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
	
	
start_recording:
	bsf	PORTF,7	    ;set the recording indication pin high
	movlw	10000000B
	movwf	TRISF
	lfsr	0, Data_array	;point to the right location
	clrf	TMR0L		;reset timer high word
	clrf	TMR0H		;reset timer low word
	bsf     T0CON, 7 ; Turn on Timer0
	return

start_replay:
	bsf	PORTF,6	    ;set the replaying indication pin high
	movlw	01000000B
	movwf	TRISF
	clrf	0x0A
	clrf	0x0B
	lfsr	0, Data_array	;point to memory location 0x100
	return

skip:
	movlw	0xFF
	cpfseq	0x03
	call	freq
	return

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

sine:
    
    
	
end	rst
