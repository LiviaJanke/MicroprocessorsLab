#include <xc.inc>

global  LCD_Setup, LCD_Write_Message

psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_nternter:	ds 1   ; reserve 1 byte for counting through nessage
LCD_counter:	ds 1

	LCD_CS1	EQU 0
	LCD_CS2	EQU 1
    	LCD_RS	EQU 2	; LCD register select bit
	LCD_RW	EQU 3	; LCD Read / Write 
	LCD_E	EQU 4	; LCD enable bit
	LCD_RST	EQU 5	; LCD Reset
	
psect	lcd_code,class=CODE
    
LCD_Setup:
	clrf    LATB, A
	movlw   11000000B	    ; RB0:5 all outputs (control line)
	movwf	TRISB, A
	clrf    LATD, A
	movlw   0x00		    ; RD0:8 all outputs (data line)
	movwf	TRISD, A
	bcf	LATB, LCD_CS1, A    ;Select both chip 1 & 2
	bcf	LATB, LCD_CS2, A
	bsf	LATB, LCD_RST, A
	bcf	LATB, LCD_RW, A
	bcf     LATB, LCD_RS, A
	bcf	LATB, LCD_E, A
	movlw   40
	call	LCD_delay_ms	    ; wait 40ms for LCD to start up properly
	movlw	0x3E		    ; Display Off
	call	LCD_Send_Instruction
	movlw	0x40		    ; Set X address (Page 0)
	call	LCD_Send_Instruction
	movlw	0xB8		    ; Set Y address (Column 0)
	call	LCD_Send_Instruction
	movlw	0x3F		    ; Display On
	call	LCD_Send_Instruction
	return

LCD_Send_Instruction:
    	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	return
	
LCD_Write_Message:		    ; Message stored at FSR2, length stored in W
	movlw	64
	movwf   LCD_counter, A
	
LCD_Loop_message:
	movf    POSTINC2, W, A
	call    LCD_Send_Byte_D
	decfsz  LCD_counter, A
	bra	LCD_Loop_message
	return

LCD_Send_Byte_I:		; Transmits byte stored in W 
	movwf   LATD, A		; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
	call    LCD_Enable	; Pulse enable Bit 
	return

LCD_Send_Byte_D:		    ; Transmits byte stored in W
	movwf   LATD	, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	    ; Data write set RS bit
	call    LCD_Enable	    ; Pulse enable Bit 
	movlw	10		    ; delay 40us
	call	LCD_delay_x4us
	return

LCD_Enable:	    ; pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATB, LCD_E, A	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, LCD_E, A	    ; Writes data to LCD
	return
   
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return


    end
