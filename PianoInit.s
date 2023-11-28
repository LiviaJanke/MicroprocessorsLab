#include <xc.inc>

global  Init_piano
extrn	LCD_Write_Message

psect	udata_acs   ; reserve data space in access ram
LCD_page:   ds 1
Loop4:	    ds 1
counter:    ds 1    ; reserve one byte for a counter variable
Top:	    ds 1    ;
    
    	LCD_CS1	EQU 0
	LCD_CS2	EQU 1
	
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

psect	data    
myTableTopLeft:
db 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
db 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 255
	
myTableBotLeft:
db 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
db 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 255, 255, 255, 255, 255
db 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
db 255, 255, 255, 255, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
	
myTableBotRight:
db 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 255, 255, 255
db 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
db 255, 255, 255, 255, 255, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
db 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
	
myTableTopRight:
db 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 255, 255, 255
db 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255
db 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0

	myTable_l   EQU	64	; length of data
	align	2
    
psect	lcd_code,class=CODE
    
Init_piano:
	movlw	0xB8
	movwf	LCD_page, A ; Set initial Page No of GLCD
	call	SetLeft
	movlw	0xB8
	movwf	LCD_page, A ; Set initial Page No of GLCD
	call	SetRight
	
	return
	
SetLeft:
	bcf	LATB, LCD_CS1, A    ;Select Left side
	bsf	LATB, LCD_CS2, A    
	movlw	4
	movwf	Loop4, A	    ; Set to go around loop 4 times (Top Left)
	bsf	Top, 0, A	    ; Select Top Left Table
	call	startLeft	  
	movlw	4
	movwf	Loop4, A	    ; Set to go around loop 4 times (Bottom Left)
	bcf	Top, 0, A	    ; Select Bottom Left Table
	call	startLeft
	
	return 
	
startLeft: 	
	lfsr	0, myArray			; Load FSR0 with address in RAM	
	btfsc	Top, 0, A
	movlw	low highword(myTableTopLeft)	; address of data in PM
	btfss	Top, 0, A
	movlw	low highword(myTableBotLeft)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	btfsc	Top, 0, A
	movlw	high(myTableTopLeft)	; address of data in PM
	btfss	Top, 0, A
	movlw	high(myTableBotLeft)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	btfsc	Top, 0, A
	movlw	low(myTableTopLeft)	; address of data in PM
	btfss	Top, 0, A
	movlw	low(myTableBotLeft)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	myTable_l		; bytes to read
	movwf 	counter, A		; our counter registery
		
loopLeft: 	
	tblrd*+				; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0	; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loopLeft		; keep going until finished
	lfsr	2, myArray		; FSR2 point to my array
	call	LCD_sendLeft
	return
	
LCD_sendLeft:
	movf	LCD_page, W, A
	call	LCD_Write_Message
	incf	LCD_page, A
	decfsz	Loop4, A		 ;Loop around 4 times to set all 4 pages on one side 
	bra	startLeft
	
	return
	
SetRight:
	bsf	LATB, LCD_CS1, A
	bcf	LATB, LCD_CS2, A	;Select right side
	movlw	4
	movwf	Loop4, A  ; Set to go around loop 4 times
	bsf	Top, 0, A
	call	startRight
	movlw	4
	movwf	Loop4, A  ; Set to go around loop 4 times
	bcf	Top, 0, A
	call	startRight
	
	return 
	
	
startRight: 	
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	btfsc	Top, 0, A
	movlw	low highword(myTableTopRight)	; address of data in PM
	btfss	Top, 0, A
	movlw	low highword(myTableBotRight)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	btfsc	Top, 0, A
	movlw	high(myTableTopRight)	; address of data in PM
	btfss	Top, 0, A
	movlw	high(myTableBotRight)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	btfsc	Top, 0, A
	movlw	low(myTableTopRight)	; address of data in PM
	btfss	Top, 0, A
	movlw	low(myTableBotRight)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	myTable_l		; bytes to read
	movwf 	counter, A		; our counter register

	
loopRight: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loopRight		; keep going until finished
	lfsr	2, myArray		; FSR2 point to my array
	call	LCD_sendRight
	return
	
LCD_sendRight:
	movf	LCD_page, W, A
	call	LCD_Write_Message
	incf	LCD_page, A
	decfsz	Loop4, A	    ;Loop around 4 times to set all 4 pages on one side 
	bra	startRight

	return
    
    




