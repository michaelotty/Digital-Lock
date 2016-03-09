
#include P16F84A.INC
__config _XT_OSC  &  _WDT_OFF & _PWRTE_ON
;File registers used by the delay
DELAY_COUNT1        EQU        H'21'
DELAY_COUNT2        EQU        H'22'
DELAY_COUNT3        EQU        H'23'
;File registers for digits required to unlock the code
Digit0                EQU        H'0C'
Digit1                EQU        H'0D'
Digit2                EQU        H'0E'
Digit3                EQU        H'0F'
Digit4                EQU        H'10'
;File registers for digits inuptted by user
D0                        EQU        H'11'
D1                        EQU        H'12'
D2                        EQU        H'13'
D3                        EQU        H'14'
D4                        EQU        H'15'
TempVar                EQU        H'16' ;Temporary storage of the digit entered by user
TempVar2            EQU        H'17'

org h'0'
    goto        MAIN
org h'4'
    call    interrupt
    return
;-------------------------------------------------------------------------------
MAIN

    bsf            STATUS,5        ;select bank 1
    movlw        B'01110000'        ;Set port RB4-6 as inputs
    movwf        TRISB
    movlw        B'00000000'        ;Set up all of PORTA as outputs
    movwf        TRISA
    bcf            STATUS,5        ;reselect bank 0
    
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
    movlw   D'0'
    movwf   TempVar2
    clrf    D0
    clrf    D1
    clrf    D2
    clrf    D3
    clrf    D4

    ;clrf    PORTB
    
    clrf    INTCON
    bsf        INTCON, RBIE        ;Interupts on RB4 -RB7
    bsf        INTCON, GIE
    bcf        INTCON, INTF

;-------------------------------------------------------------------------------
CodeSetUp
    
loop
;Output to row 1 + display L
    movlw   B'11110011'
    movwf   PORTA    
    movlw   B'00000001'
    movwf   PORTB
    call    delay2
;Output to row 2 + display L
    movlw   B'11110011'
    movwf   PORTA    
    movlw   B'00000010'
    movwf   PORTB
    call    delay2
;Output to row 3 + display L
    movlw   B'11110011'
    movwf   PORTA    
    movlw   B'00000100'
    movwf   PORTB
    call    delay2
;Output to row 4 + display L
    movlw   B'11110011'
    movwf   PORTA    
    movlw   B'00001000'
    movwf   PORTB
    call    delay2
    goto    loop

;-------------------------------------------------------------------------------
interrupt
;    movwf        TempVar2
tag1    
    call    Conversion    
    call    VariableCheck
    movfw   D4   
    xorlw   D'0' ;Checks if the lastdigit has been entered before checking if the digits are correct
    btfss   STATUS,Z
    call    CodeCheck
    debounce
    btfsc   PORTB,4
    goto    debounce
    btfsc   PORTB,5
    goto    debounce
    btfsc   PORTB,6
    goto    debounce
    bcf     INTCON, RBIF
    retfie
    
delay2        ;delay inbetween powering rows
    movlw   H'30'           
    movwf   DELAY_COUNT1
delay_loop2
    decfsz  DELAY_COUNT1,F
    goto    delay_loop2  
    return
    
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
    movlw   D'11'
    movwf   TempVar
    btfss   PORTB,6
    goto    skip_clear
    clrf    D0
    clrf    D1
    clrf    D2
    clrf    D3
    clrf    D4
    
    
    
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
    return
    
FirstDigit     
    movfw   D1
    xorlw   D'0'
    btfss   STATUS,Z
    goto    SecondDigit
    movfw   TempVar
    movwf   D1
;    movlw   B'00000000'
;    movwf   PORTB
    
    return
    
SecondDigit    
    movfw   D2   
    xorlw   D'0'
    btfss   STATUS,Z
    goto    ThirdDigit
    movfw   TempVar
    movwf   D2
;    movlw   B'00000001'
;    movwf   PORTB
    return
    
ThirdDigit     
    movfw   D3   
    xorlw   D'0'
    btfss   STATUS,Z
    goto    FourthDigit
    movfw   TempVar
    movwf   D3
;    movlw   B'00000010'
;    movwf   PORTB
    return
    
FourthDigit     
    movfw   D4   
    xorlw   D'0'
    btfss   STATUS,Z
    return
    movfw   TempVar
    movwf   D4
;    movlw   B'000000011'
;    movwf   PORTB
    return     
    
;-------------------------------------------------------------------------------
CodeCheck
;Checks each digit against the pre-determined digits when all 4 digits and # have been entered
    movlw   B'00000011'
    movwf   PORTB
    
    movfw   D0
    subwf   Digit0,w    ;Subtract D0 from Digit 1
    btfss   STATUS,Z    ;If they are the same the Z flag is set to 0 so the other digits are checked
    return    ;If the entered digit is wrong the code immediately returns (cpuld change later to display failed or summat)
        
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
    call    Unlock ;When all digits have been checked, if they're correct it unlocks
    return
    
;-------------------------------------------------------------------------------
;Display U
Unlock
;fixit
    movlw   B'11111010'
    movwf   PORTA    
    movlw   B'01110000'
    movwf   PORTB
;fixit
    call    delay
    return
    

end

