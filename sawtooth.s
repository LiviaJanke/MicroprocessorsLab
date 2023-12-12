#include <xc.inc>

;extrn	DAC_Int_Hi_sine, DAC_Int_Hi_square
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
;RCsquare	equ	3
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

;ARRAY_LENGTH      equ 10     
	    
	    
	    
main:
	org	0x0
	bsf	TRISB, RBG	; Set PORTB as input
	bsf	TRISE, REE
	bsf	TRISJ, RJDs	; Set PORTH as input
	bsf	TRISC, RCsawtooth
	bcf	TRISF, 7
	bcf	TRISF, 6
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	movlw	0x10
	movwf	0x02
	BANKSEL 0x100
	clrf	0x100
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;bsf	TRISC,2,A ; configure CCP1 pin for input
	;movlw	0x81 ; use Timer1 as the time base
	;movwf	T3CON,A ; of CCP1 capture
	;bcf	CCP1IE,A ; disable CCP1 capture interrupt
	;movlw	0x81 ; enable Timer1, prescaler set to 1,
	;movwf	T1CON,A ; 16-bit, y use instruction cycle clock
	;movlw	0x03 ; set CCP1 to capture on every edge
	;movwf	CCP1CON,A ; "
	;bcf	CCP1IF,A ; clear the CCP1IF flag
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lfsr	0, Data_array 
	;movlw   LOW(Data_array)    ; Load the low byte of DATA_ARRAY address into W
	;movwf   FSR0L              ; Load the W register into FSR0L
	;movlw   HIGH(Data_array)   ; Load the high byte of DATA_ARRAY address into W
	;movwf   FSR0H              ; Load the W register into FSR0H
	;movlw	low highword(Data_array)	; address of data in PM
	movlw	0x01
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	;movlw	high(Data_array)	; address of data in PM
	movlw	0xFF
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	;movlw	low(Data_array)	; address of data in PM
	movlw	0xEA
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        bsf     TMR0IE ; Enable Timer0 overflow interrupt
        bsf	GIE    ; Enable global interrupts
	movlw	10000111B	; Set timer0 to 16-bit, prescaler:1/256
	movwf	T0CON, A
	clrf    TMR0          ; Clear Timer0
        
	org	0x100		    ; Main code starts here at address 0x100
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
change_signal:
	
	;BANKSEL 0x100 
	;movlw	0x03
	;movwf	0x100
	;movlw	0x00
	;movwf	0x101
	;movlw	0x03
	;movwf	0x102
	;movlw	0x02
	;movwf	0x103
	;movlw	0x01
	;movwf	0x104
	;movlw	0x01
	;movwf	0x105
	
	btfsc	PORTC,RCsawtooth	;check if want to change signal
	goto	sawtooth
	;btfsc	PORTC,RCsine
	;call	DAC_Int_Hi_sine
	;btfsc	PORTC,RCsquare
	;call	DAC_Int_Hi_square
	goto	change_signal		;loop to wait for choice of waveform
	
sawtooth:   ;sawtooth waveform branch
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
	;call	replayON    ;if yes go to replaying branches
	call	prescaler
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
	
	;call	hugedelay
	;call	deaddelay
	;call	deaddelay
	btfsc	TRISF,6	    ;test if record mode is turned on
	call	delay    ;if yes go to recording branches
	;movlw 	0xFF	    ; The count down max
	;cpfsgt 	0x06, A	    ; Test if the counter reached the max count number
	goto 	loop		    ; Re-run program from start

;Recording Branches;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start_recording:
	bsf	PORTF,7	    ;set the recording indication pin high
	movlw	10000000B
	movwf	TRISF
	lfsr	0, Data_array	;point to the right location
	bsf     T0CON, 7 ; Turn on Timer0
	clrf	0x0F	    ;clear the pre-stored comparator in 0x0F and prepare for recording
	
	return
stop_recording:
	bcf	PORTF,7	    ;clear the recording indication pin
	movlw	00000000B
	movwf	TRISF
	bcf     T0CON, 7 ; Turn off Timer0
	return
recordON:
	cpfseq	0x0F	    ; test if a different note is played
	call	recording	;when note is different, store time
	return
recording:
	movwf	0x0F	    ;move the note indication into 0x0F for comparison in the next round
	movff	0x03,POSTINC0	;move frequency to memory
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	movff	TMR0H,POSTINC0      ; Write the high word to the current location in the array
	movff	TMR0L,POSTINC0      ; Write the low word to the current location 
	;;;;;;;;;;;;;;;;;;;reset and restart the timer for the next stage change
	clrf	TMR0H		;reset timer high word
	clrf	TMR0L		;reset timer low word
	;bsf     T0CON, 7	    ; Turn on Timer0 again
	return
;Replay Branches;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start_replay:
	bsf	PORTF,6	    ;set the replaying indication pin high
	movlw	01000000B
	movwf	TRISF
	clrf	0x0A
	clrf	0x0B
	lfsr	0, Data_array	;point to memory location 0x100
	;goto	sawtooth
	return
stop_replay:
	bcf	PORTF,6	    ;set the replaying indication pin high
	movlw	00000000B
	movwf	TRISF
	return
replayON:
	tstfsz	0x0B	    ;test if low word of duration is 0, if 0, test high word
	goto	duration    ;low word of duration is not 0, so maintain previous frequency
	tstfsz	0x0A	    ;test if high word of duration is also 0, if 0, load new note in memory
	goto	duration    ;high word of duration is not 0, so maintain previous frequency
	call	music_load  ;load next note played in memory
	return
music_load:
	movff	INDF0,0x03		;move frequency number into 0x03
	movff	0x03,0x00		;move the frequency into 0x00 for backup use
	incf	FSR0L		;increment FSR0 low word
	btfsc	STATUS,2	;test if FSR0L incremented to 0xFF
	incf	FSR0H		;if overflowed, increment FSR0H
	movff	INDF0,0x0A		;move high word of duration to 0x0A
	incf	FSR0L		;same job as the previous one
	btfsc	STATUS,2	
	incf	FSR0H		
	movff	INDF0,0x0B		;move low word of duration to 0x0B
	incf	FSR0L		;same job as the previous ones
	btfsc	STATUS,2	
	incf	FSR0H	
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
	call	condition
	return
condition:
	movlw	0x10
	movwf	0x02
	incf	0x01
	movlw	0xCF
	cpfslt	0x01
	goto	replayON
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
	return
;PORT J notes
NoteRJGs:
	movlw	0x45 
	movwf	0x03, A
	movlw	0x17
	return
NoteRJA:
	movlw	0x40 
	movwf	0x03, A
	movlw	0x16
	return
NoteRJAs:
	movlw	0x3B 
	movwf	0x03, A
	movlw	0x15
	return
NoteRJB:
	movlw	0x38 
	movwf	0x03, A
	movlw	0x14
	return
NoteRJC:
	movlw	0x36
	movwf	0x03, A
	movlw	0x13
	return	
NoteRJCs:
	movlw	0x32 
	movwf	0x03, A
	movlw	0x12
	return	
NoteRJD:
	movlw	0x2F 
	movwf	0x03, A
	movlw	0x11
	return
NoteRJDs:
	movlw	0x2D 
	movwf	0x03, A
	movlw	0x10
	return
;PORT E notes
NoteREE:
	movlw	0x30 
	movwf	0x03, A
	movlw	0x0F
	return
NoteREF:
	movlw	0x2B 
	movwf	0x03, A
	movlw	0x0E
	return
NoteREFs:
	movlw	0x26 
	movwf	0x03, A
	movlw	0x0D
	return
NoteREG:
	movlw	0x23 
	movwf	0x03, A
	movlw	0x0C
	return
NoteREGs:
	movlw	0x1E
	movwf	0x03, A
	movlw	0x0B
	return	
NoteREA:
	movlw	0x1A 
	movwf	0x03, A
	movlw	0x0A
	return	
NoteREAs:
	movlw	0x16 
	movwf	0x03, A
	movlw	0x09
	return
NoteREB:
	movlw	0x13 
	movwf	0x03, A
	movlw	0x08
	return
;PORT B notes
NoteRBC:
	movlw	0x20 
	movwf	0x03, A
	movlw	0x07
	return
NoteRBCs:
	movlw	0x1D 
	movwf	0x03, A
	movlw	0x06
	return
NoteRBD:
	movlw	0x1A 
	movwf	0x03, A
	movlw	0x05
	return
NoteRBDs:
	movlw	0x17 
	movwf	0x03, A
	movlw	0x04
	return
NoteRBE:
	movlw	0x14 
	movwf	0x03, A
	movlw	0x03
	return	
NoteRBF:
	movlw	0x11 
	movwf	0x03, A
	movlw	0x02
	return	
NoteRBFs:
	movlw	0x0E 
	movwf	0x03, A
	movlw	0x01
	return
NoteRBG:
	movlw	0x0C 
	movwf	0x03, A
	movlw	0x19
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
	
	
end	sawtooth
