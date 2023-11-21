#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Write_Message
extrn	keypad_Setup, keypad_Read, keyval
    
global	myArray
    
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x8 ; reserve 8 bytes for message data

	
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup LCD
	call	keypad_Setup	; setup Keypad
	goto	start
	
	; ******* Main programme ****************************************
start: 	;lfsr	0, myArray	; Load FSR0 with address in RAM	
	call	keypad_Read
	movlw	keyval
;	lfsr	2, myArray
;	call	UART_Transmit_Message
;	movlw	keyval
	addlw	0xff
;	lfsr	2, myArray
	call	LCD_Write_Message
	call	delay	
;	goto	start
	goto	$
	; a delay subroutine if you need one, times around loop in delay_count
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return
bigdelay:
	call delay
	call delay
	call delay
	call delay 
	call delay
	return
	
	end	rst