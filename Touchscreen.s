#include <xc.inc>

global  ADC_Setup, Change_Freq

psect	udata_acs   
x_pos:	ds 1
y_pos:	ds 1
note:	ds 1
freq_rollover:   ds 1
tmp:	ds 1	
	
psect	lcd_code,class=CODE
    
ADC_Setup: 
    
	;Set Port F as input and Port E as output
    	setf TRISF, A    ; all input
	clrf TRISE, A    ; all output
	
	; set RF2 and RF5 as analogue input
	banksel ANCON0
	clrf ANCON0, B
	bsf ANCON0, 5, B  
	bsf ANCON0, 7, B
	
	movlb	0
	movlw	1        ;Turn ADC 
	movwf	ADCON0, A 
	movlw	00100000B ; 2.048 V
	movwf	ADCON1, A
	movlw	0x1B ; Left Justified
	movwf	ADCON2, A


	return
	
Change_Freq:
	call	read_x
	call	ADC_Read
	movwf	x_pos, A
	call	read_y
	call	ADC_Read
	movwf	y_pos, A
	call	Convert_notes
	call	Convert_Freq
	
	return

read_x:
	;supplying Drive A (RE4) with voltage
	clrf	LATE, A
	bsf	LATE, 4, A
	
	;Send RF5 input to ADC input
	banksel	ADCON0
	movlw	0101001B  ;AN10(RF5) 
	movwf	ADCON0, A
	movlb	0

	return

read_y:
	;supplying Drive B (RE5) with voltage
	clrf	LATE, A
	bsf	LATE, 5, A
	
	;Send RF2 input to ADC input
	banksel	ADCON0
	movlw	0011101B  ;AN7	(RF2) 
	movwf	ADCON0, A
	movlb	0

	return
	
ADC_Read:
	bsf	GO
	
ADC_Loop:
	btfsc	GO
	bra	ADC_Loop
	
	movf	ADRESH, W, A
	return
	

	
Convert_notes:
	movlw	69  ; Callibrated mid-point voltage of y-pos
	CPFSGT	y_pos, A    ; If below implies bottom half of keyboard
	call    xBottomhalfnote 
	CPFSLT	y_pos, A 
	call	xTophalfnote
	movlw	38  ; Callibrated voltage level at px 0 (y-pos)
	CPFSGT	y_pos, A 
	call	Nonote
	
	return
	

xBottomhalfnote: ;Total of 5 notes at bottom half with uniquely asssigned binary code (0, 11, 1111, 11111, 1111111)
	clrf	note, A
	movlw	37  
	CPFSLT	x_pos, A  
	bsf	note, 0, A
	CPFSLT	x_pos, A  
	bsf	note, 1, A
	movlw	52 
	CPFSLT	x_pos, A  
	bsf	note, 2, A
	CPFSLT	x_pos, A  
	bsf	note, 3, A
	movlw	69  
	CPFSLT	x_pos, A  
	bsf	note, 4, A
	movlw	88  
	CPFSLT	x_pos, A  
	bsf	note, 5, A
	CPFSLT	x_pos, A  
	bsf	note, 6, A	
	
	return
	
xTophalfnote: ;Total of 9 notes at top half with uniquely asssigned binary code (0, 1, 11, 111, 1111, 11111, 111111, 1111111, 11111111)
	clrf	note, A
	movlw	34  
	CPFSLT	x_pos, A  
	bsf	note, 0, A
	movlw	43  
	CPFSLT	x_pos, A  
	bsf	note, 1, A
	movlw	47 
	CPFSLT	x_pos, A  
	bsf	note, 2, A
	movlw	55
	CPFSLT	x_pos, A  
	bsf	note, 3, A
	movlw	64
	CPFSLT	x_pos, A  
	bsf	note, 4, A	
	movlw	75
	CPFSLT	x_pos, A  
	bsf	note, 5, A	
	movlw	81
	CPFSLT	x_pos, A  
	bsf	note, 6, A
	movlw	85
	CPFSLT	x_pos, A  
	bsf	note, 7, A

	return
	
Nonote: 
    	movlw	10B    ; 10 Bit pattern for no note is played
	movwf	note, A	
	
	return
	
Convert_Freq:
    
	;Picks out each note and assign rollover number to output right frequency
	movlw	0
	CPFSGT	note, A
	bra	NoteC
	movlw	1B
	CPFSGT	note, A
	bra	NoteCs
	movlw	10B  ; 01 Bit pattern No button pressed
	CPFSGT	note, A
	bra	disableSound
	movlw	11B
	CPFSGT	note, A
	bra	NoteD
	movlw	111B
	CPFSGT	note, A
	bra	NoteDs
	movlw	1111B
	CPFSGT	note, A
	bra	NoteE
	movlw	11111B
	CPFSGT	note, A
	bra	NoteF
	movlw	111111B
	CPFSGT	note, A
	bra	NoteFs
	movlw	1111111B
	CPFSGT	note, A
	bra	NoteG
	movlw	11111111B
	CPFSGT	note, A
	bra	NoteGs
	
disableSound:
	
	movlw	0
	movwf	freq_rollover, A ;Or disable DAC when outputing sine wavee
	
	return

NoteC:
	movlw   0x89
	movwf   freq_rollover, A
	
	return
	
NoteCs:
	movlw   0x8F
	movwf   freq_rollover, A
	
	return
	
NoteD:
	movlw   0x96
	movwf   freq_rollover, A
	
	return

NoteDs:
	movlw   0x9C
	movwf   freq_rollover, A
	
	return

NoteE:
	movlw   0xA1
	movwf   freq_rollover, A
	
	return

NoteF:
	movlw   0xA6
	movwf   freq_rollover, A
	
	return
	
NoteFs:
	movlw   0xAC
	movwf   freq_rollover, A
	
	return

NoteG:
	movlw   0xB0
	movwf   freq_rollover, A
	
	return

NoteGs:
	movlw   0xB5
	movwf   freq_rollover, A
	
	return

    end




