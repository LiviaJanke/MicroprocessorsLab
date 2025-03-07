	#include <xc.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
start:
	movlw 	0x0
	movwf	TRISC, A	    ; Port C all outputs
	bra 	test
loop:
	movff 	0x06, PORTC
	incf 	0x06, W, A
test:
	movwf	0x06, A	    ; Test for end of loop condition
	movlw 	0xFF
	cpfsgt 	0x06, A
	call	hugedelay
	bra 	loop		    ; Not yet finished goto start of loop again
	goto 	0x0		    ; Re-run program from start

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
	
	
;bigdelay:
	;movlw	0x00
;dloop:	decf	0x11, f, A
	;subwfb	0x10, f, A
	;return
	
	end	main
