#include P16F84A.INC
__config _XT_OSC  &  _WDT_OFF & _PWRTE_ON

DELAY_COUNT1    EQU     H'21'
DELAY_COUNT2    EQU     H'22'
DELAY_COUNT3    EQU     H'23'
;File registers for pre-determined digits 
Digit1			EQU     H'0D' 
Digit2			EQU     H'0E'
Digit3			EQU     H'0F'
Digit4			EQU     H'10'
;File registers for digits inutted by user
D1				EQU     H'11'
D2				EQU     H'12'
D3				EQU     H'13'
D4				EQU     H'14'
HashTag	                        EQU     H'15' 
TempVar		                EQU     H'16' ;Temporary storage of the digit entered by user

org h'0'
    goto    	MAIN
org h'4'
    call    interrupt
    goto    loop
;-------------------------------------------------------------------------------
MAIN

    bsf     STATUS,5        ;select bank 1
    movlw   B'01110000'        ;Set port RB4-6 as inputs
    movwf   TRISB
    movlw   B'00000000'        ;Set up all of PORTA as outputs
    movwf   TRISA
    bcf   	STATUS,5        ;reselect bank 0
    
    ;Initialise the 4-digit code as 1234
    movlw   D'1'
    movwf   Digit1
    movlw   D'2'
    movwf   Digit2
    movlw   D'3'
    movwf   Digit3
    movlw   D'4'
    movwf   Digit4

    clrf    PORTB
    
    clrf    INTCON
    bsf	    INTCON, RBIE        ;Interupts on RB4 -RB7
    bsf	    INTCON, GIE
    bcf	    INTCON, INTF

;-------------------------------------------------------------------------------
CodeSetUp
    
loop
;Display L
    movlw   B'11100001'
    movwf   PORTA    
    movlw   B'11111011'
    movwf   PORTB
;Output to row 1
    movlw   B'11100001'
    movwf   PORTA    
    movlw   B'11111001'
    movwf   PORTB
    call    delay2
    clrf    PORTB
;Output to row 2
    movlw   B'11100101'
    movwf   PORTA    
    movlw   B'11111000'
    movwf   PORTB
;Output to row 3
    movlw   B'11100001'
    movwf   PORTA    
    movlw   B'11111010'
    movwf   PORTB
;Output to row 4
    movlw   B'11101001'
    movwf   PORTA    
    movlw   B'11111000'
    movwf   PORTB
    goto    loop

;-------------------------------------------------------------------------------
interrupt
    btfsc   HashTag,0
    goto    tag1
    btfss   PORTB,2
    goto    loop
    btfss   PORTB,6
    goto    loop
    movlw   D'1' 
    movwf   HashTag
tag1    
    call    Conversion    
    call    VariableCheck
    movfw   D4   
    xorlw   D'0'
    btfsc   STATUS,Z
    call    CodeCheck
    bcf     INTCON, RBIF
    retfie
    
delay2		|;delay inbetween powering segments
    movlw   H'20'           
    movwf   DELAY_COUNT1
delay_loop2
    decfsz  DELAY_COUNT1,F
    goto    delay_loop2  

    return
    
;-------------------------------------------------------------------------------
Conversion

Row1
    btfss   PORTB,0
    goto    Row2    
    btfsc   PORTB,4
    movlw   D'1'
    btfsc   PORTB,5
    movlw   D'2'
    btfsc   PORTB,6
    movlw   D'3'
    movwf		TempVar
Row2
    btfss   PORTA,3
    goto    Row3    
    btfsc   PORTB,4
    movlw   D'4'
    btfsc   PORTB,5
    movlw   D'5'
    btfsc   PORTB,6
    movlw   D'6'
    movwf		TempVar
Row3
    btfss   PORTB,3
    goto    Row4    
    btfsc   PORTB,4
    movlw   D'7'
    btfsc   PORTB,5
    movlw   D'8'
    btfsc   PORTB,6
    movlw   D'9'
    movwf		TempVar
Row4
    btfss   PORTB,2
    goto    Row1  
    btfsc	  PORTB,4
    nop
    btfsc   PORTB,5
    movlw   D'0'
    btfss   PORTB,6
    goto    skip_clear
    clrf    D1
    clrf    D2
    clrf    D3
    clrf    D4
    
    
skip_clear
	  movwf		TempVar         
    return
    
;-------------------------------------------------------------------------------
CodeCheck
		
    movfw   D1   
    subwf   Digit1,w
    btfss   STATUS,Z
    return
    
    movfw   D2
    subwf   Digit2,w
    btfss   STATUS,Z
    return
    
    movfw   D3
    subwf   Digit3,w
    btfss   STATUS,Z
    return
    
    movfw   D4
    subwf   Digit4,w
    btfsc   STATUS,Z
    call    Unlock
    return
	
;-------------------------------------------------------------------------------
;Display U
Unlock
;fixit
    movlw   B'11111100'
    movwf   PORTA    
    movlw   B'11111101'
    movwf   PORTB
;fixit
    call    delay2
    call    delay2
    call    delay2
    call    delay2
    call		delay2
    clrf    PORTB
    clrf    PORTA
    return
    
VariableCheck
     
    movfw   D1   
    xorlw   D'0'
    btfss   STATUS,Z
    movfw	TempVar
    movwf   D1
    
    movfw   D2   
    xorlw   D'0'
    btfss   STATUS,Z
    movfw	TempVar
    movwf   D2
    
    movfw   D3   
    xorlw   D'0'
    btfss   STATUS,Z
    movfw	TempVar
    movwf   D3
     
    movfw   D4   
    xorlw   D'0'
    btfss   STATUS,Z
    movfw	TempVar
    movwf   D4

    return     
end
