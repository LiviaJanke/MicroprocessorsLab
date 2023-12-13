#include <xc.inc>

;extrn	UART_Setup, UART_Transmit_Message  ; external subroutines
	
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

psect	data    
	; ******* myTable, data in programme memory, and its length *****
myTable:
	db	'H','e','l','l','o',' ','m','y','H','A','P','P','Y',' ','W','o','r','l','d','!',0x0a
					; message, plus carriage return
	myTable_l   EQU	21	; length of data
	align	2
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	movlw	0x10
	movwf	0x02
	;call	UART_Setup	; setup UART
	goto	start
	
	; ******* Main programme ****************************************
start: 	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	myTable_l	; bytes to read
	movwf 	counter, A		; our counter register
loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	call	prescaler
	;bra	loop		; keep going until finished
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;lfsr	0, myArray
interrupt:
	movlw D?249? ; load 249 into PR2 so that TMR2 counts up
	movwf PR2,A ; to 249 and reset
	bsf RCON, , IPEN A ; py p enable priority interrupt
	bsf IPR1,TMR2IP,A ; place TMR2 interrupt at high priority
	bcf PIR1,TMR2IF,A ;
	movlw 0xC0
	movwf INTCON,A ;g p enable global interrupt
	movlw 0x7E ; enable TMR2, set prescaler to 16, set
	movwf T2CON,A ; postscaler to 16
	bsf PIE1,TMR2IE,A ; enable TMR2 overflow interrupt
	
read:	
	;tblrd*+
	movf	INDF0,W
	incf	FSR0L
	btfsc	STATUS,2
	incf	FSR0H
	movff	INDF0,0x0A
	incf	FSR0L
	btfsc	STATUS,2
	incf	FSR0H
	movff	INDF0,0x0B
	incf	FSR0L
	btfsc	STATUS,2
	incf	FSR0H
	
	movlw	0x02
	movwf	0x0B
	movlw	0x01
	movwf	0x0A
	;goto	0x14
durat:
	decf	0x0B
	
	
duration:
	dcfsnz	0x0B
	call	multi_delay
	
	tstfsz	0x0B
	goto	duration
	tstfsz	0x0A
	goto	duration
 	goto	read
	;movlw	POSTINC0
	;movlw	myTable_l	; output message to UART
	;lfsr	2, myArray
	;call	UART_Transmit_Message

	;goto	$		; goto current line in code

	; a delay subroutine if you need one, times around loop in delay_count
multi_delay:
	tstfsz	0x0A
	call	more_delay
	return
more_delay:
	decf	0x0A
	decf	0x0B
	return
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return

	end	rst


