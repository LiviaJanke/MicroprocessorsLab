#include <xc.inc>

; allow to import these from other files
;global  Storage_setup, Storage_start, Storage_read
    
psect	storage_code,class=CODE
Storage_setup:
    setf    TRISD
    banksel PADCFG1	    ; configure register
    bsf     REPU
    movlb   0x00
    clrf    TRISC, A
    movlw   0XFF
    movwf   PORTC, A
    OE1     EQU    1	    ; Location for the output register 1
    CP1     EQU    3	    ; Location for the clock control 1
    OE2     EQU    2	    ; Location for the output register 2
    CP2     EQU    4	    ; Location for the clock control 2
    movlw   0x4		    ; setting size of delay
    ;  ******** Set the locations for the cascading delay counters ********
    movwf   0x40, A	    
    movff   0x40, 0x41	    
    movff   0x40, 0x140	    
    movff   0x40, 0x43
    movff   0x40, 0x44
    movlw   0x0
    call    Storage_start
    return

Storage_start: 
    movf    0x03, W, A        ; Get Caesar Cipher Key from keypad
    call    write	      ; store Caesar Cipher Key in external memory
    ;movlw   0x0 
    ;movwf   0x09	      ; Erase Caesar Cipher key from memory
    ;movf    0x10, W, A	      ; Get XOR Key from keypad
    ;call    write2	      ; store XOR Key in external memory
    ;movlw   0x0 
    ;movwf   0x10	      ; Erase XOR key from memory
    return
    
write:
    clrf    TRISD, A	      ; setup PORT D
    movwf   PORTD, A
    BCF     PORTC, CP1, A     ; lower the bit for the control pulse
    movff   0x21, 0x22, A
    call    Delay
    BSF     PORTC, CP1, A     ; vlaue is written to the memory
    return

;write2:
;    clrf    TRISD, A	      ; setup PORT D
;    movwf   PORTD, A
;    BCF     PORTC, CP2, A     ; lower the bit for the control pulse
;    movff   0x21, 0x22, A
;    call    Delay
;   BSF     PORTC, CP2, A     ; vlaue is written to the memory
;    return
    
Storage_read:
    movlw   0x0
    setf    TRISD, A            ; Change PORT D to input
    BCF     PORTC, OE1, A	; Set correct pins for output
    movff   0x140, 0x40
    call    Delay
    movff   PORTD, 0x50
    movff   0x140, 0x40
    call    Delay
    BSF	    PORTC, OE1, A	; Set correct pins for output
   
    movlw   0x0
    setf    TRISD, A            ; Change PORT D to input
    BCF     PORTC, OE2, A	; Set correct pins for output
    movff   0x140, 0x40
    call    Delay
    movff   PORTD, 0x51
    movff   0x140, 0x40
    call    Delay
    BSF	    PORTC, OE2, A       ; Set correct pins for output
    return

;  ******** Cascading delays ********
Delay: 
    movff   0x140, 0x41
    call    Delay2
    decfsz  0x40, A
    bra     Delay
    return
    
Delay2: 
    movff   0x140, 0x43
    call Delay3
    decfsz  0x41, A
    bra     Delay2
    return
    
Delay3: 
    movff   0x140, 0x44
    call    Delay4
    decfsz  0x43, A
    bra     Delay3
    return
    
Delay4: 
    decfsz  0x44, A
    bra     Delay4
    return
    


