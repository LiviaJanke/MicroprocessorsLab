#include <xc.inc>
    
global  converter

extrn	LCD_delay_ms
    
psect	udata_acs   ; reserve data space in access ram
tempchar: ds    1	    ; reserve 1 byte for variable UART_counter

psect	converter_code,class=CODE

converter:
    movwf    tempchar
    
test_0:
    movlw   0x00	
    cpfseq  tempchar	
    bra	    test_1
    retlw   0x30	   
test_1:
    movlw   0x01
    cpfseq  tempchar	
    bra	    test_2
    retlw   0x31
test_2:
    movlw   0x02
    cpfseq  tempchar	
    bra	    test_3
    retlw   0x32
test_3:
    movlw   0x03	
    cpfseq  tempchar	
    bra	    test_4
    retlw   0x33
test_4:
    movlw   0x04	
    cpfseq  tempchar	
    bra	    test_5
    retlw   0x34
test_5:
    movlw   0x05
    cpfseq  tempchar	
    bra	    test_6
    retlw   0x35	
test_6:
    movlw   0x06
    cpfseq  tempchar	
    bra	    test_7
    retlw   0x36
test_7:
    movlw   0x07	
    cpfseq  tempchar
    bra	    test_8
    retlw   0x37
test_8:
    movlw   0x08
    cpfseq  tempchar	
    bra	    test_9
    retlw   0x38
test_9:
    movlw   0x09	
    cpfseq  tempchar	
    bra	    test_A
    retlw   0x39
test_A:
    movlw   0x0A
    cpfseq  tempchar	
    bra	    test_B
    retlw   0x41
test_B:
    movlw   0x0B
    cpfseq  tempchar	
    bra	    test_C
    retlw   0x42
test_C:
    movlw   0x0C
    cpfseq  tempchar	
    bra	    test_D
    retlw   0x43
test_D:
    movlw   0x0D
    cpfseq  tempchar	
    bra	    test_E
    retlw   0x44
test_E:
    movlw   0x0E
    cpfseq  tempchar	
    bra	    test_F
    retlw   0x45
test_F:
    movlw   0x0F
    cpfseq  tempchar	
    retlw   0x46
    bra	    test_invalid
test_invalid:    
    retlw   0x3F



