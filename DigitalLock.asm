#include P16F84A.INC
__config _XT_OSC  &  _WDT_OFF & _PWRTE_ON
;File registers used by the delay
DELAY_COUNT1        EQU        H'21'
DELAY_COUNT2        EQU        H'22'
DELAY_COUNT3        EQU        H'23'
;File registers for digits required to unlock the code
Digit0              EQU        H'0C'
Digit1              EQU        H'0D'
Digit2              EQU        H'0E'
Digit3              EQU        H'0F'
Digit4              EQU        H'10'
Digit5            EQU        H'11'
;File registers for digits inuptted by user
D0                  EQU        H'12'
D1                  EQU        H'13'
D2                  EQU        H'14'
D3            EQU        H'15'
D4            EQU        H'16'
TempVar            EQU        H'17' ;Temporary storage of the digit entered by user
TempVar2            EQU        H'18'
TempVar3        EQU        H'19'

org h'0'
    goto    MAIN
org h'4'
    call    interrupt
    return
;-------------------------------------------------------------------------------
MAIN

    bsf        STATUS,5        ;select bank 1
    movlw   B'01110000'        ;Set port RB4-6 as inputs
    movwf   TRISB
    movlw   B'00000000'        ;Set up all of PORTA as outputs
    movwf   TRISA
    bcf        STATUS,5        ;reselect bank 0
    
    ;Initialise the 4-digit code as #1234
    movlw   D'11' ;11 = #
    movwf   Digit0
    movlw   D'1'
    movwf   Digit1
    movlw   D'2'
    movwf   Digit2
    movlw   D'3'
    movwf   Digit3
    movlw   D'4'
    movwf   Digit4
    movlw   D'10'
    movwf   Digit5
    clrf    D0
    clrf    D1
    clrf    D2
    clrf    D3
    clrf    D4
    clrf    TempVar2
    clrf    TempVar3

    ;clrf    PORTB
    
    clrf    INTCON
    bsf        INTCON, RBIE        ;Interupts on RB4 -RB7
    bsf        INTCON, GIE
    bcf        INTCON, INTF

;-------------------------------------------------------------------------------   
loop
    movfw   D0
    xorlw   D'0'
    btfss   STATUS,Z
    goto    tag1
;Display L    
    movlw   B'11110011'
    movwf   PORTA
    call    CycleRows
    goto    loop

tag1 ;Leave whatever is on PORTA the way it is
    call    CycleRows
    goto    loop
    
;-----------------------------------------------------------------------------------
CycleRows
;Output to row 1
    movlw   B'00000001'
    movwf   PORTB
    call    delay2
;Output to row 2    
    movlw   B'00000010'
    movwf   PORTB
    call    delay2
;Output to row     
    movlw   B'00000100'
    movwf   PORTB
    call    delay2
;Output to row 4    
    movlw   B'00001000'
    movwf   PORTB
    call    delay2
    return
    
;--------------------------------------------------------------------------------    
delay2        ;delay inbetween powering rows
    movlw   H'30'           
    movwf   DELAY_COUNT1
delay_loop2
    decfsz  DELAY_COUNT1,F
    goto    delay_loop2  
    return
    
delay3
    movlw           H'FF'           ;initialise delay counters
    movwf           DELAY_COUNT1
    movlw           H'FF'
    movwf           DELAY_COUNT2
    movlw           H'04'
    movwf           DELAY_COUNT3
delay_loop3
    decfsz          DELAY_COUNT1,F  ; inner most loop
    goto            delay_loop3     ; decrements and loops until delay_count1=0
    decfsz          DELAY_COUNT2,F  ; middle loop
    goto            delay_loop3
    decfsz          DELAY_COUNT3,F  ; outer loop
    goto            delay_loop3
    return
;-------------------------------------------------------------------------------
interrupt
    btfss   TempVar2,0
    goto    tag3
    btfsc   TempVar3,0
    goto    tag2
    call    Conversion
    call    VariableCheck
    ;ERROR IS SOMEWHERE HERE, SIMULATE AND CHECK
    movfw   D4
    xorlw   D'0'
    btfss   STATUS,Z
    ;ERROR IS SOMEWHERE HERE, SIMULATE AND CHECK
    call    SwapVariables
    goto    debounce    
      
tag2    
    call    Conversion
    call    VariableCheck
    movfw   D4
    xorlw   D'0'
    btfss   STATUS,Z
    call    CodeCheck2
    goto    debounce
tag3  
    call    Conversion    
    call    VariableCheck
;    movlw   B'11111011'
;    movwf   PORTA
    movfw   D4   
    xorlw   D'0' ;Checks if the lastdigit has been entered before checking if the digits are correct
    btfss   STATUS,Z
    call    CodeCheck
    movfw   D4   
    xorlw   D'0' ;Checks if the lastdigit has been entered before checking if the digits are correct
    btfss   STATUS,Z
    call    ChangeCheck
    
debounce
    btfsc   PORTB,4
    goto    debounce
    btfsc   PORTB,5
    goto    debounce
    btfsc   PORTB,6
    goto    debounce    
    call    delay3
    bcf     INTCON, RBIF
    retfie
   
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
    movwf   TempVar
    return
Row2
    btfss   PORTB,1
    goto    Row3
    btfsc   PORTB,4
    movlw   D'4'
    btfsc   PORTB,5
    movlw   D'5'
    btfsc   PORTB,6
    movlw   D'6'
    movwf   TempVar
    return
Row3
    btfss   PORTB,2
    goto    Row4   
    btfsc   PORTB,4
    movlw   D'7'
    btfsc   PORTB,5
    movlw   D'8'
    btfsc   PORTB,6
    movlw   D'9'
    movwf   TempVar
    return
Row4
    btfss   PORTB,3
    return
    btfsc   PORTB,4
    movlw   D'10' ;10 = *
    btfsc   PORTB,5
    movlw   D'0'
    btfsc   PORTB,6
    movlw   D'11' ;11 = #
    movwf   TempVar
    btfss   PORTB,6
    goto    skip_clear
    call    clear
    btfss   PORTB,4
    goto    skip_clear
    call    clear
skip_clear
    movwf   TempVar  
    return
    
    
;-------------------------------------------------------------------------------
VariableCheck  
;Checks if D0-4 are empty before putting new values in them.
    movfw   D0
    xorlw   D'0' ;Exclusive OR D0 with 0
    btfss   STATUS,Z ;If D0 is empty it moves the value in TempVar to 'D0'
    goto    FirstDigit ;If not, it checks the next variable (D1)
    movfw   TempVar
    movwf   D0
    movlw   B'11111111'
    movwf   PORTA
    call    delay3
    return
    
FirstDigit     
    movfw   D1
    xorlw   D'0'
    btfss   STATUS,Z
    goto    SecondDigit
    movfw   TempVar
    movwf   D1
    movlw   B'11111110'
    movwf   PORTA
    return
    
SecondDigit    
    movfw   D2   
    xorlw   D'0'
    btfss   STATUS,Z
    goto    ThirdDigit
    movfw   TempVar
    movwf   D2
    movlw   B'11111100'
    movwf   PORTA    
    return
    
ThirdDigit     
    movfw   D3   
    xorlw   D'0'
    btfss   STATUS,Z
    goto    FourthDigit
    movfw   TempVar
    movwf   D3
    movlw   B'11111000'
    movwf   PORTA
    return
    
FourthDigit     
    movfw   D4   
    xorlw   D'0'
    btfss   STATUS,Z
    return
    movfw   TempVar
    movwf   D4
    movlw   B'11110000'
    movwf   PORTA
    return     
    
;-------------------------------------------------------------------------------
CodeCheck
;Checks each digit against the pre-determined digits when all 4 digits and # have been entered
    
    movfw   D0
    subwf   Digit0,w    ;Subtract D0 from Digit 1
    btfss   STATUS,Z ;If they are the same the Z flag is set to 0 so the other digits are checked
    return   
        
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
;Display U + wait 5 seconds
Unlock
    movlw   B'11111010'
    movwf   PORTA    
    movlw   B'01110000'
    movwf   PORTB
    call    delay
    call    clear
    return
    
;-------------------------------------------------------------------------------    
delay
    movlw           H'FF'           ;initialise delay counters
    movwf           DELAY_COUNT1
    movlw           H'FF'
    movwf           DELAY_COUNT2
    movlw           H'1A'
    movwf           DELAY_COUNT3
delay_loop
    decfsz          DELAY_COUNT1,F  ; inner most loop
    goto            delay_loop      ; decrements and loops until delay_count1=0
    decfsz          DELAY_COUNT2,F  ; middle loop
    goto            delay_loop
    decfsz          DELAY_COUNT3,F  ; outer loop
    goto            delay_loop
    return
    
;-----------------------------------------------------------------------------     
clear
    clrf    D0
    clrf    D1
    clrf    D2
    clrf    D3
    clrf    D4
    return
    
ChangeCheck
    movfw   D0
    subwf   Digit5,w    
    btfss   STATUS,Z
    call    clear    ;If the code is incorrect the Variables D0-4 are cleared   
        
    movfw   D1   
    subwf   Digit4,w
    btfss   STATUS,Z
    call    clear
    
    movfw   D2
    subwf   Digit3,w
    btfss   STATUS,Z
    call    clear
    
    movfw   D3
    subwf   Digit2,w
    btfss   STATUS,Z
    call    clear
    
    movfw   D4
    subwf   Digit1,w
    btfsc   STATUS,Z
    goto    tag5
    call    clear
    return
    
tag5    
    movlw   D'1'
    movwf   TempVar2
    call    clear
    return
    
;------------------------------------------------------------------------------
;After the new code has been ebtered once, it swaps the variables
SwapVariables
    movlw   B'00000000'
    movwf   PORTA
    movfw   D0
    movwf   Digit0
    movfw   D1
    movwf   Digit1
    movfw   D2
    movwf   Digit2
    movfw   D3
    movwf   Digit3
    movfw   D4
    movwf   Digit4
    clrf    D0
    clrf    D1
    clrf    D2
    clrf    D3
    clrf    D4
    movlw   D'1'
    movwf   TempVar3
    return
    
;------------------------------------------------------------------------------    
CodeCheck2
;    movlw   B'11111110'
;    movwf   PORTA
    movfw   D0
    subwf   Digit0,w    
    btfss   STATUS,Z    
    return    
        
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
    goto    tag4
    call    InitialiseCode
    ;Display n
    movlw   B'11111000'
    movwf   PORTA
    movlw   B'11111111'
    movwf   PORTB
tag4
    call    CodeSetUp
    return

;------------------------------------------------------------------------------------
;If the user fails to change the code, it resets to #1234
InitialiseCode
    movlw   D'11' ;11 = #
    movwf   Digit0
    movlw   D'1'
    movwf   Digit1
    movlw   D'2'
    movwf   Digit2
    movlw   D'3'
    movwf   Digit3
    movlw   D'4'
    movwf   Digit4
    movlw   D'10' ;10 = *
    movwf   Digit5
    return
    
;---------------------------------------------------------------------------------------    
CodeSetUp
;If the user sucessfully changes the code, the new code is noved to the reisters and S is displayed
    movlw   B'11101000'
    movwf   PORTA
    movfw   D1
    movwf   Digit1
    movfw   D2
    movwf   Digit2
    movfw   D3
    movwf   Digit3
    movfw   D4
    movwf   Digit4
    call    clear
    clrf    TempVar2
    clrf    TempVar3
    return
end

