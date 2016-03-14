;Laurabelle Kakulu and Michael Otty
#include P16F84A.INC
__config _XT_OSC  &  _WDT_OFF & _PWRTE_ON
;File registers used by the TwoHertzDelay
DELAY_COUNT1        EQU        H'21'
DELAY_COUNT2        EQU        H'22'
DELAY_COUNT3        EQU        H'23'
;File registers for digits required to unlock/change the code
Digit0              EQU        H'0C'
Digit1              EQU        H'0D'
Digit2              EQU        H'0E'
Digit3              EQU        H'0F'
Digit4              EQU        H'10'
Digit5              EQU        H'11'
;File registers for digits inputted by user
D0                  EQU        H'12'
D1                  EQU        H'13'
D2                  EQU        H'14'
D3                  EQU        H'15'
D4                  EQU        H'16'
TempVar             EQU        H'17' ;Temporary storage of the digit entered by user
MasterCodeEntered   EQU        H'18' ;Is set to 1 when when the mastercode is entered, otherwise is 0
NewCodeEntered1     EQU        H'19' ;Is set to 1 when the new code has been entered once
Count               EQU        H'1A' ;Counter to determine how long 'U' flashes for
BuzzerCount	        EQU	       H'1B'			       

org h'0'
    goto    MAIN
;org h'4'
;    call    interrupt
;    return
;-------------------------------------------------------------------------------
MAIN

    bsf     STATUS,5        ;select bank 1
    movlw   B'01110000'        ;Set port RB4-6 as inputs
    movwf   TRISB
    movlw   B'00000000'        ;Set up all of PORTA as outputs
    movwf   TRISA
    bcf     STATUS,5        ;reselect bank 0
    
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
    movlw   D'10' ;10 = *
    movwf   Digit5
    clrf    D0
    clrf    D1
    clrf    D2
    clrf    D3
    clrf    D4
    clrf    MasterCodeEntered
    clrf    NewCodeEntered1

    ;clrf    PORTB
    
;    clrf	INTCON
;    bsf        INTCON, RBIE        ;Interupts on RB4 -RB7
;    bsf        INTCON, GIE
;    bcf        INTCON, INTF

;-------------------------------------------------------------------------------   
loop
    movlw   H'A' 
    movwf   Count ;Count used when the safe is unlocked.
    
    movfw   D0
    xorlw   D'0'
    btfss   STATUS,Z ;If a digit has been pressed, instead of displaying L, it displays what was last moved to the ports.
    goto    tag1
;Display L    
    movlw   B'11110011'
    movwf   PORTA
    call    CycleRows
    goto    loop

tag1 ;Leave whatever is on the ports the way it is. 
    call    CycleRows
    goto    loop
    
;-----------------------------------------------------------------------------------
CycleRows
;Output to row 1.
    movlw   B'00000001'
    movwf   PORTB
    call    ButtonCheck
    call    RowDelay
;Output to row 2.    
    movlw   B'00000010'
    movwf   PORTB
    call    ButtonCheck
    call    RowDelay
;Output to row.     
    movlw   B'00000100'
    movwf   PORTB
    call    ButtonCheck
    call    RowDelay
;Output to row 4.    
    movlw   B'00001000'
    movwf   PORTB
    call    ButtonCheck
    call    RowDelay
    return

;-----------------------------------------------------------------------------------
;Checks for voltage at RB4-6.    
ButtonCheck
    btfsc   PORTB,4
    call    PushedButton
    btfsc   PORTB,5
    call    PushedButton
    btfsc   PORTB,6
    call    PushedButton
    return
    
;--------------------------------------------------------------------------------   
;Delay inbetween powering rows.
RowDelay        
    movlw   H'30'           
    movwf   DELAY_COUNT1
RowDelay_loop
    decfsz  DELAY_COUNT1,F
    goto    RowDelay_loop  
    return
    
;-------------------------------------------------------------------------------
PushedButton
    movlw   D'255'
    movwf   BuzzerCount
    btfss   MasterCodeEntered,0 ;Checks if the mastercode has been entered.
    goto    tag3 ;If not, skips to tag 3.
    btfsc   NewCodeEntered1,0 ;Ater the mastercode has been entered, checks if a new code has been etered once.
    goto    tag2 ;If so, skips to tag2.
    call    Conversion
    call    VariableCheck
    movfw   D4
    xorlw   D'0'
    btfss   STATUS,Z
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
    movfw   D4   
    xorlw   D'0' ;Checks if the lastdigit has been entered before checking if the digits are correct.
    btfss   STATUS,Z
    call    CodeCheck
    movfw   D4   
    xorlw   D'0' 
    btfss   STATUS,Z
    call    ChangeCheck
debounce   
    btfsc   PORTB,4
    goto    debounce
    btfsc   PORTB,5
    goto    debounce
    btfsc   PORTB,6
    goto    debounce
    call    Buzz
    bsf     STATUS,5        ;select bank 1
    movlw   B'01110000'        ;Set port RB4-6 as inputs
    movwf   TRISB
    bcf     STATUS,5
    return
    
Buzz    
    bsf     STATUS,5        ;select bank 1
    movlw   B'01100000'     ;Set port RB4-6 as inputs
    movwf   TRISB
    bcf     STATUS,5 
    call    Beep
    decfsz  BuzzerCount
    goto    Buzz 
    return
    
Beep
    movlw   B'00010000'
    movwf   PORTB
    call    RowDelay
    call    RowDelay
    movlw   B'00000000'
    movwf   PORTB
    call    RowDelay    
    call    RowDelay
    return   
;-------------------------------------------------------------------------------
;Uses row and column data to determine which number was pressed i.e if RB0 (Row1) and RB4(Col1) are both set, the number pressed was '1'.
Conversion
Row1
    btfss   PORTB,0 ;if thre is no voltage at this row, it skips to the next one.
    goto    Row2    
    btfsc   PORTB,4 
    movlw   D'1'
    btfsc   PORTB,5
    movlw   D'2'
    btfsc   PORTB,6
    movlw   D'3'
    movwf   TempVar ;Move the correct value to the temporary storage.
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
    movlw   D'12' ;0 is set to 12 because a value of 0 would cause a variable to register as empty.
    btfsc   PORTB,6
    movlw   D'11' ;11 = #
    movwf   TempVar
    btfss   PORTB,6
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
    return     
    
;-------------------------------------------------------------------------------
CodeCheck
;Checks each digit against the pre-determined digits when all 4 digits and # have been entered
    movfw   D0
    subwf   Digit0,w    ;Subtract D0 from Digit 1
    btfss   STATUS,Z ;If they are the same the Z flag is set to 1 so the other digits are checked
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
    call    clear
    call    Flash
    decfsz  Count ;Call flash until Count gets to 0
    goto    Unlock
    return ;Return to showing locked
    
;-------------------------------------------------------------------------------
;Cycles between displaying U and turning the segment off at 2Hz
Flash
    movlw   B'11111010'
    movwf   PORTA 
    movlw   B'00000000'
    movwf   PORTB
    call    TwoHertzDelay
    movlw   B'11111111'
    movwf   PORTA
    movlw   B'11111111'
    movwf   PORTB
    call    TwoHertzDelay
    return
    
;-------------------------------------------------------------------------------    
TwoHertzDelay
    movlw           H'A8'           ;initialise TwoHertzDelay counters
    movwf           DELAY_COUNT1
    movlw           H'45'
    movwf           DELAY_COUNT2
    movlw           H'02'
    movwf           DELAY_COUNT3
TwoHertzDelay_loop
    decfsz          DELAY_COUNT1,F  ; inner most loop
    goto            TwoHertzDelay_loop      ; decrements and loops until TwoHertzDelay_count1=0
    decfsz          DELAY_COUNT2,F  ; middle loop
    goto            TwoHertzDelay_loop
    decfsz          DELAY_COUNT3,F  ; outer loop
    goto            TwoHertzDelay_loop
    return  
    
;-------------------------------------------------------------------------------     
clear
    clrf    D0
    clrf    D1
    clrf    D2
    clrf    D3
    clrf    D4
    return
    
ChangeCheck
;If the code entered doesn't match the unlock code, the code is checked against the master code.
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
    movwf   MasterCodeEntered
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
    movwf   NewCodeEntered1 
    return
    
;------------------------------------------------------------------------------    
;Checks that the two new codes entered by the user are the same
CodeCheck2
    movfw   D0
    subwf   Digit0,w    
    btfss   STATUS,Z    
    goto    Unsucessful    
        
    movfw   D1   
    subwf   Digit1,w
    btfss   STATUS,Z
    goto    Unsucessful
    
    movfw   D2
    subwf   Digit2,w
    btfss   STATUS,Z
    goto    Unsucessful
    
    movfw   D3
    subwf   Digit3,w
    btfss   STATUS,Z
    goto    Unsucessful
    
    movfw   D4
    subwf   Digit4,w
    btfsc   STATUS,Z
    goto    tag4
    goto    Unsucessful ;If the two codes do not match, reset the code to #1234
    

tag4
    call    CodeSetUp
    return
    
Unsucessful    
    ;Display n
    movlw   B'11111000'
    movwf   PORTA
    movlw   B'11111111'
    movwf   PORTB
    call    TwoHertzDelay
    call    InitialiseCode ;If the two codes do not match, reset the code to #1234
    return
    
;---------------------------------------------------------------------------------------    
CodeSetUp
;If the user sucessfully changes the code, the new code is noved to the reisters and S is displayed
    movlw   B'11100100'
    movwf   PORTA
    call    TwoHertzDelay
    movfw   D1
    movwf   Digit1
    movfw   D2
    movwf   Digit2
    movfw   D3
    movwf   Digit3
    movfw   D4
    movwf   Digit4
    call    clear 
    clrf    MasterCodeEntered
    clrf    NewCodeEntered1
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
    call    clear
    return
    

end

