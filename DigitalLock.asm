#include P16F84A.INC
__config _XT_OSC  &  _WDT_OFF & _PWRTE_ON

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
    movlw   B'11111001'
    movfw   PORTB
    movlw   B'11111101'
    movfw   PORTA
    goto loop

interupt

    retfie

end
    
    
