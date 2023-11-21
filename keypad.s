#include <xc.inc>
  
global  keypad_Setup, keypad_Read, keyval, low_bits

psect	udata_acs   ; reserve data space in access ram
keypad_counter: ds    1	    ; reserve 1 byte for variable UART_counter

psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x40)
keyval:    ds 0x8 ; reserve 8 bytes for message data
low_bits:  ds 0x8
    
    
psect	keypad_code,class=CODE
    
keypad_Setup:

    movlb   15	; pad configure 1 is in 15?
    bsf	    REPU    ; set pull-ups to on for PORTE
    movlb   0
    clrf    LATE    ; write 0s to the lat e register
    MOVLW   0CFh
    MOVWF   TRISD
    clrf    LATD
    return

    
keypad_Read:
    movlw   0x0F
    movwf   TRISE
    call    bigdelay   ; can add a delay here to prevent need for status checks
    movff   PORTE, low_bits ; read the 4 PORTE pins
    movlw   0xF0    
    movwf   TRISE   ; set TRISE to 0x0F
    

test_none:
    movlw   0xFF
    cpfseq  keyval, A
    bra	    test_0
    retlw   0x00

test_0:
    movf    PORTE, W ;  read PORTE to determine the logic levels on PORTE 0-3      
    iorwf   low_bits, W
    movwf   keyval
    movf    keyval, W
    movwf   PORTD
    call    delay
    goto    keypad_Read
    
    
delay:	decfsz	0xFF, A	; decrement until zero
	bra	delay
	return

bigdelay:
	call delay
	call delay
	call delay
	call delay 
	call delay
	call delay
	call delay
	call delay
	call delay 
	call delay
	return





