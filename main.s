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
	movff 	0xFF, PORTC
	incf 	0x06, W, A


test:
	movwf	0x06, A	    ; Test for end of loop condition
	;movf    PORTD, W, A
	;movf	PORTD, W, B
	;movlb	0xf
	;movf	PORTD, W, B
	;movf	PORTD, W
	movlw	0xFF
	cpfsgt 	0x06, A
	call	delay
	bra 	loop		    ; Not yet finished goto start of loop again
	goto 	0x0		    ; Re-run program from start


delay:	decfsz	0x20, A
	bra	delay
	return

	end	main
