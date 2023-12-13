#include <xc.inc>
    
global	delay, bigdelay, hugedelay, deaddelay	    

psect	delay_code, class = CODE   

    
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
	


