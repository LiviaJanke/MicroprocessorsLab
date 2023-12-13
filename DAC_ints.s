#include <xc.inc>

extrn	Recording, Replay
global	DAC_Setup, DAC_Int_Hi, freq_replay

psect	udata_acs
counter1: ds 1
counter2: ds 1
freq_rollover: ds 1
freq_replay: ds 1    

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
    
    
psect	dac_code, class=CODE
	
;DAC_Int_Hi:	
;	btfss	TMR0IF		; check that this is timer0 interrupt
;	retfie	f		; if not then return
;	incf	LATJ, F, A	; increment PORTD
;	bcf	TMR0IF		; clear interrupt flag
;	retfie	f		; fast return from interrupt
	
DAC_Int_Hi:	; Outputs Square pulse (Uncomment to output sine with DAC)
	movwf	freq_rollover, A
	btfss	TMR0IF		;Test the Timer0 interrupt flag (TMR0IF).
				;If it is clear (skips the next instruction), jump to the Record label.
	bra	Record		; Branch to Recording if timer1 interrupt    
	movlw	0xFF
	movwf	TMR0H, A	
	movff	freq_rollover, TMR0L, A	; assign to the lower 8 bits
	tstfsz	freq_rollover, A

	;call	Squarewave
	call	sawtooth
	bcf	TMR0IF		; clear interrupt flag
	retfie	f		; fast return from interrupt

	

;DAC_Setup:
;	clrf	TRISJ, A	; Set PORTD as all outputs
;	clrf	LATJ, A		; Clear PORTD outputs
;	movlw	10000111B	; Set timer0 to 16-bit, Fosc/4/256
;	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
;	bsf	TMR0IE		; Enable timer0 interrupt
;	bsf	GIE		; Enable all interrupts
;	return
;	
;	end
	
DAC_Setup:
	
	clrf PORTD
    
	bsf	TRISB, RBG	; Set PORTB as input
	bsf	TRISE, REE
	bsf	TRISJ, RJDs	; Set PORTH as input
	bsf	TRISC, RCsawtooth
	bcf	TRISF, 7
	bcf	TRISF, 6
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	movlw	0x10
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
	
	movlw	10000111B	; Set timer0 to 16-bit, prescaler:1/256
	movwf	T0CON, A
	bsf     TMR0IE          ; Enable Timer0 overflow interrupt
	
	movlw	00110111B	; Set timer1 to 16-bit, 2MHz
	movwf	T1CON, A
	bsf	TMR1IE
	bsf	PEIE	
	
        bsf	GIE    ; Enable global interrupts

	return

	
Record:
	btfsc	Recording, 0, A	    ; Check Recording mode enabled
	call	Store_note
	btfsc	Replay, 0, A	    ; Check Replay mode enabled
	movff	POSTINC0, freq_replay, A    
	bcf	TMR1IF		; clear interrupt flag
	retfie	f		; fast return from interrupt
	return
	
Squarewave:
	tstfsz	LATJ, A
	decfsz	LATJ, A
	incf	LATJ, A

	return
	
Store_note: ;Store freq_rollover into data memory
	movlw	0x0E		
	cpfslt	FSR0H, A	; rollover when FSR0 points to bank 15
	lfsr	0, 0x200        ; Start memory storage at Bank 2, use pointer 0
	incf	LATH, A
	movff	freq_rollover, POSTINC0, A
	return
	
	
	end



