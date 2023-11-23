#include <xc.inc>
    
global  keypad_output, combineddata,columndata, rowdata

extrn	LCD_delay_ms
    
psect	udata_acs   ; reserve data space in access ram
columndata: ds    1	    ; reserve 1 byte for variable UART_counter
rowdata:ds  1
combineddata:ds	1

psect	keypad_code,class=CODE

keypad_setup:

    movlw   0x0F    ;Move 00001111 to WR
    movwf   TRISE   ;Sets lower 4 bits to 1-configures them as inputs
    movlb   0x0F    ;Loads 1111 to BSR
    bsf	    REPU    ;Makes SBR15 ready for inputs
    movlb   0x00    ;Loads 0000 to lower bits of BSR 
    clrf    LATE
    return

    
keypad_read:
    
    call    keypad_setup
    movlw   0x01
    call    LCD_delay_ms
    movf    PORTE, W
    movwf   rowdata
    call    keypad_flip
    movlw   0x01
    call    LCD_delay_ms
    movf    PORTE, W
    movwf   columndata
    movf    rowdata, W
    iorwf   columndata, W
    movwf   combineddata
    return    
    
keypad_flip:
    movlw   0xF0    ;Move 11110000 to WR
    movwf   TRISE   ;Sets lower 4 bits to 0 - configures them as inputs
    movlb   0x0F    ;
    bsf	    REPU    ;Makes SBR15 ready for inputs
    movlb   0x00    ;Loads 0000 to lower bits BSR 
    clrf    LATE
    return

keypad_output:
    call    keypad_read
    bra	    test_none
    return

test_none:
    movlw   0xFF
    cpfseq  combineddata	
    bra	    test_0
    retlw   0xFF	
test_0:
    movlw   0xEB	
    cpfseq  combineddata	
    bra	    test_1
    retlw   0x0E	   
test_1:
    movlw   0x77	
    cpfseq  combineddata	
    bra	    test_2
    retlw   0x01
test_2:
    movlw   0x7B
    cpfseq  combineddata	
    bra	    test_3
    retlw   0x04
test_3:
    movlw   0x7D	
    cpfseq  combineddata	
    bra	    test_4
    retlw   0x07
test_4:
    movlw   0xB7	
    cpfseq  combineddata	
    bra	    test_5
    retlw   0x02
test_5:
    movlw   0xBB
    cpfseq  combineddata	
    bra	    test_6
    retlw   0x05	
test_6:
    movlw   0xBD
    cpfseq  combineddata	
    bra	    test_7
    retlw   0x08
test_7:
    movlw   0xD7	
    cpfseq  combineddata
    bra	    test_8
    retlw   0x03
test_8:
    movlw   0xDB
    cpfseq  combineddata	
    bra	    test_9
    retlw   0x06
test_9:
    movlw   0xDD	
    cpfseq  combineddata	
    bra	    test_A
    retlw   0x09
test_A:
    movlw   0xE7
    cpfseq  combineddata	
    bra	    test_B
    retlw   0x0F
test_B:
    movlw   0xED
    cpfseq  combineddata	
    bra	    test_C
    retlw   0x0D
test_C:
    movlw   0xEE
    cpfseq  combineddata	
    bra	    test_D
    retlw   0x0C
test_D:
    movlw   0xDE
    cpfseq  combineddata	
    bra	    test_E
    retlw   0x0B
test_E:
    movlw   0xBE
    cpfseq  combineddata	
    bra	    test_F
    retlw   0x00
test_F:
    movlw   0x7E
    cpfseq  combineddata	
    bra	    invalid
    retlw   0x0A
invalid:
    bra	    keypad_output



	