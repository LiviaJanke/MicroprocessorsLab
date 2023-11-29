#include <xc.inc>
Global	Recording, Replay
    
extrn	UART_Setup, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_clear,keypad_output, LCD_Send_Char_D, LCD_Write_Hex 
extrn	converter
extrn	DAC_Setup, DAC_Int_Hi
extrn	ADC_Read	
extrn	Init_piano
extrn	ADC_Setup, Change_Freq
extrn	Clear_Recording, freq_replay
    
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
freq_rollover: ds 1
delay_num:  ds 1
Recording:  ds 1
Replay: ds 1
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

psect	data    
	; ******* myTable, data in programme memory, and its length *****
myTable:
	db	'H','e','l','l','o',' ','W','o','r','l','d','!',0x0a
					; message, plus carriage return
	myTable_l   EQU	13	; length of data
	align	2
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

int_hi:	
	org	0x0008	; high priority interrpy
	movf	freq_rollover, W, A	; Move freq_rollover to W
	btfsc	Replay, 0, A		; Bit Test f, Skip if Clear
	movf	freq_replay, W, A	; Move replay to W if replay mode enabled
	goto	DAC_Int_Hi	
	
	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup UART
	call	Init_piano
	call	ADC_Setup
	call	DAC_Setup
	setf	TRISC, A    ; all input (control unit for start & stop replay / recording and clear memory) 
	goto	start
	goto	main
	
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
	goto	main
	
main:
	btfss	Replay, 0, A		; Bit Test File, Skip if Set
	call	Change_Freq		; Stores detected input to W
	movwf	freq_rollover, A	; Move W to freq-rollover
	
	btfsc	PORTC, 0, A      ; If Pin 0 of Port C pressed, set Recording True
	bsf	Recording, 0, A	    ; Bit ?b? of the register indicated by FSR2,
				    ; offset by the value ?k?, is set
	
	btfsc	PORTC, 1, A	  ; If Pin 1 of Port C pressed, set Recording False
	bcf	Recording, 0, A
	
	btfsc	PORTC, 2, A      ; If Pin 2 of Port C pressed, Clear Recording
	call	Clear_Recording
	
	btfsc	PORTC, 3, A      ; If Pin 3 of Port C pressed, Set replay True
	call	Replay_Music
	
	btfsc	PORTC, 4, A      ; If Pin 4 of Port C pressed, Set Replay False
	bcf	Replay, 0, A	; Bit ?b? in register ?f? is cleared.
	

	movlw	0xAA		; Add in some delay to reduce boucing issues
	movwf	delay_num, A
	
loop:
	movlw	0xFF
	movwf	delay_count, A
	call	delay
	decfsz	delay_num, A
	bra	loop
	
	bra	start
	
	goto	$		; goto current line in code	
	
;loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
;	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
;	decfsz	counter, A		; count down to zero
;	bra	loop		; keep going until finished
		
;	movlw	myTable_l	; output message to UART
;	lfsr	2, myArray
;	call	UART_Transmit_Message

;	movlw	myTable_l	; output message to LCD
;	addlw	0xff		; don't send the final carriage return to LCD
;	lfsr	2, myArray
;	call	LCD_Write_Message
;	call	LCD_clear
;	call	keypad_output
;	call	converter
;	call	LCD_Send_Char_D
;	goto	$		; goto current line in code

	; a delay subroutine if you need one, times around loop in delay_count
	
;measure_loop:
;	call	ADC_Read
;	movf	ADRESH, W, A
;	call	LCD_Write_Hex
;	movf	ADRESL, W, A
;	call	LCD_Write_Hex
;	goto	measure_loop		; goto current line in code	


	
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return
	
Replay_Music:	; Called when RC3 pressed
	bsf	Replay, 0, A
	lfsr	0, 0x200        ; Start memory storage at Bank 2, use FSR0
	return

	end	rst