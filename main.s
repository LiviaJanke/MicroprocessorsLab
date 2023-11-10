	#include <xc.inc>

psect	code, abs

SPI_MasterInit:	;set clock edge to negative
    bcf	CKE2	; CKE bit in SSP2STAT
    ; MSSP enable; CKP=1p; SPI master, clock = Fosc/64 (1MhZ)
    movlw   (SSP2CON1_SSPEN_MASK)|(SSP2CON1_CKP_MASK)|(SSP2CON1_SSPM1_MASK)
    movwf   SSP2CON1, A
    ; SDO2 output; SCK2 output
    bcf	TRISD, PORTD_SDO2_POSN, A  ; SDO2 output
    bcf	TRISD, PORTD_SCK2_POSN, A   ; SCK2 ouput

SPI_MasterTransmit: ; start transmission of data (held in W)
    movwf   SSP2BUF, A	;write data to output buffer
    
Wait_Transmit:	    ; Wait for transmission to complete
    btfss   PIR2, 5  ; Check interrupt flag to see if data has been sent
    bra	    Wait_Transmit
    bcf	    PIR2, 5  ; clear interrupt flag
    call    hugedelay
    return
    
delay:
	decfsz	0xFF
	bra delay
	return
bigdelay:
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	call	delay
	return
bigbigdelay:
	call bigdelay
	call bigdelay
	call bigdelay
	return
bigbigbigdelay:
	call bigbigdelay
	call bigbigdelay
	call bigbigdelay
	call bigbigdelay
	call bigbigdelay
	call bigbigdelay
	call bigbigdelay
	call bigbigdelay
	call bigbigdelay
	return
hugedelay:
	call bigbigbigdelay
	call bigbigbigdelay
	call bigbigbigdelay
	call bigbigbigdelay
	call bigbigbigdelay
	call bigbigbigdelay
	call bigbigbigdelay
	call bigbigbigdelay
	call bigbigbigdelay
	call bigbigbigdelay
	call bigbigbigdelay
	return
	
	

