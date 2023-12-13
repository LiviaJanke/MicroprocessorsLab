#include <xc.inc>
    
    
global stop_recording, recordON
global	stop_replay, replayON, music_load

psect	record_replay_code, class=CODE

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

	movff	TMR0L,POSTINC0      ; Write the high word to the current location in the array
	movff	TMR0H,POSTINC0      ; Write the low word to the current location 

	movff	0x0E,0x0F	    ;move the note indication into 0x0F for comparison in the next round
	movff	0x03,POSTINC0	;move frequency to memory
	;;;;;;;;;;;;;;;;;;;reset and restart the timer for the next stage change
	clrf	TMR0L		;reset timer high word
	clrf	TMR0H		;reset timer low word
	
	return
    
stop_replay:
	bcf	PORTF,6	    ;set the replaying indication pin high
	movlw	00000000B
	movwf	TRISF
	return

replayON:
	clrf	0x01
	movff	0x00, 0x03	;move the pre-saved backup frequency value to 0x03 for this round of delay
	tstfsz	TMR0L	    ;test if low word of duration is 0, if 0, test high word
	return    ;low word of duration is not 0, so maintain previous frequency
	tstfsz	TMR0H	    ;test if high word of duration is also 0, if 0, load new note in memory
	return    ;high word of duration is not 0, so maintain previous frequency
	call	music_load  ;load next note played in memory
	
	return

music_load:
	bcf	INTCON,2
	movff	INDF0,0x03		;move frequency number into 0x03
	movff	0x03,0x00		;move the frequency into 0x00 for backup use
	incf	FSR0L		;increment FSR0 low word
	btfsc	STATUS,2	;test if FSR0L incremented to 0xFF
	incf	FSR0H		;if overflowed, increment FSR0H
	movff	INDF0,TMR0H		;move high word of duration to 0x0A
	incf	FSR0L		;same job as the previous one
	btfsc	STATUS,2	
	incf	FSR0H		
	movff	INDF0,TMR0L		;move low word of duration to 0x0B
	incf	FSR0L		;same job as the previous ones
	btfsc	STATUS,2	
	incf	FSR0H
	movlw	10000000B	; Set timer0 to 16-bit, prescaler:1/256
	movwf	T0CON, A
	return

duration:
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


    
    


