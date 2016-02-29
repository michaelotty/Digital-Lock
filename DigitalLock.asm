#include P16F84A.INC
__config _XT_OSC  &  _WDT_OFF & _PWRTE_ON

DELAY_COUNT1    EQU     H'21'
DELAY_COUNT2    EQU     H'22'
DELAY_COUNT3    EQU     H'23'

org h'0'
    goto    MAIN
org h'4'
    call    interupt
    goto    loop

MAIN

    bsf	    STATUS,5	    ;select bank 1
    movlw   B'01110000'	    ;Set port RB3-6 as inputs
    movwf   TRISB
    movlw   B'00000000'	    ;Set up all of PORTA as outputs
    movwf   TRISA
    bcf	    STATUS,5	    ;reselect bank 0

    clrf    PORTB
    
    clrf    INTCON
    bsf	    INTCON, RBIE	    ;Interupts on RB4 -RB7
    bsf	    INTCON, GIE
    bcf	    INTCON, INTF

loop
    ;Display L
    movlw   B'11111101'
    movwf   PORTA    
    movlw   B'11111001'
    movwf   PORTB
    call    delay2
    clrf    PORTB
    clrf    PORTA
    ;Output to row 1
    movlw   B'00000001'
    movwf   PORTB
    movlw   B'00000001'
    movwf   PORTA
    call    delay2
    clrf    PORTB
    clrf    PORTA
    ;Display L
    movlw   B'11111101'
    movwf   PORTA    
    movlw   B'11111001'
    movwf   PORTB
    call    delay2
    clrf    PORTB
    clrf    PORTA
    ;Output to row 2
    movlw   B'00001000'
    movwf   PORTA
    call    delay2
    clrf    PORTB
    clrf    PORTA
    ;Display L
    movlw   B'11111101'
    movwf   PORTA    
    movlw   B'11111001'
    movwf   PORTB
    call    delay2
    clrf    PORTB
    clrf    PORTA
    ;Output to row 3
    movlw   B'00001000'
    movwf   PORTB
    call    delay2
    clrf    PORTB
    clrf    PORTA
    ;Display L
    movlw   B'11111101'
    movwf   PORTA    
    movlw   B'11111001'
    movwf   PORTB
    call    delay2
    clrf    PORTB
    clrf    PORTA
    ;Output to row 4
    movlw   B'00000100'
    movwf   PORTB
    call    delay2
    clrf    PORTB
    clrf    PORTA
    ;Display L
    movlw   B'11111101'
    movwf   PORTA    
    movlw   B'11111001'
    movwf   PORTB
    call    delay2
    clrf    PORTB
    clrf    PORTA
    goto    loop

interupt
    btfss   PORTB,0
    call    something
    
    movlw   B'11111101'
    movwf   PORTA    
    movlw   B'11110001'
    movwf   PORTB 
    goto    interupt
    retfie
    
;something
;    movlw   B'11111101'
;    movwf   PORTA    
;    movlw   B'11110001'
;    movwf   PORTB
;    return
    
delay2 ;delay inbetween powering segments
    movlw   H'AA'           ;initialise delay counters
    movwf   DELAY_COUNT1
delay_loop2 
    decfsz  DELAY_COUNT1,F 
    goto    delay_loop2  

    return
end
    
    
