name "morse_code_generator"  

org 100h 
include "emu8086.inc"
jmp initialize
.DATA 
    A db ".-***"
    B db "-...*"
    C db "-.-.*"
    D db "-..**"
    E db ".****"
    F db "..-.*"
    G db "--.**"
    H db "....*"
    I db "..***"
    J db ".---*"
    K db "-.-**"
    L db ".-..*"
    M db "--***"
    N db "-.***"
    O db "---**"
    P db ".--.*"
    Q db "--.-*"
    R db ".-.**"
    S db "...**"
    T db "-****"
    U db "..-**"
    V db "...-*"
    W db ".--**"
    X db "-..-*"
    Y db "-.--*"
    Z db "--..*" 
    ;numbers 
    zero db "-----"
    one db ".----"
    two db "..---"
    three db "...--"
    four db "....-"
    five db "....."
    six db "-...."
    seven db "--..."
    eight db "---.."
    nine db "----."
    
    ;variables
    msg1 db "Welcome to morse code generator.",10,13,"$"  
    msg2 db 10,13,"Letters will be seperated by a single space",10,13,"Words will be seperated by 2 spaces",10,13,10,13,"$"
    msg3 db 10,13,"Thank you! $"
    prompt1 db 10,13,"Enter the alphanumeric string you want to convert:",10,13,10,13,"$"
    prompt2 db 10,13,"Would you like to try again? (Y/N): $"
    user_input db 50,?,50 dup('') 
       
.CODE    
initialize: 
    mov AH, 9
    lea DX, msg1
    int 21h
    
    mwanzo:
    mov AH, 9
    lea DX, prompt1
    int 21h 

     
    ;read input
    mov AH, 0Ah
    lea DX, user_input
    int 21h
    
    PUTC 10D
    PUTC 13D
    
    mov AH, 9
    lea DX, msg2
    int 21h  
    
    call read_string
    
    mov AH, 9
    lea DX, prompt2 
    int 21h
    
    mov AH, 1h
    int 21h
    ;char is stored in AL
    ;send to upper case
    AND AL, 0DFh       
    cmp AL, 'Y'
    ;jne asanti
    ;at this point user wants to retry
    je mwanzo
    
    asanti:
    mov AH, 9
    lea DX, msg3
    int 21h
    
    mov AX, 1500d
    call delay ;delay function will delay the value in AX. In milliseconds
               ;1s = 1000 milliseconds

     
RET ;main func return 

;this function returns the morse offset 
;of the letter in AX            
get_letter_morse PROC
    ;receives argument in AX 
    ;pop AX
    sub AL, 'A'
    ;AL now has the difference 
    ;between the letter and A
    mov BL, 5h  
    mul BL
    ;AX now has the difference in offset 
    ;between the letter and letter A
    ;store the offset of A in DX 
    mov DX, offset A 
    ;shift the offset by the difference (AL)
    add DX, AX
     
    ;store the offset in the stack
    ;pop BX
    ;push DX
    ;push BX 
    ret
get_letter_morse ENDP
    
;the following function returns 
;the morse offset of the number in AX       
get_number_morse PROC 
    ;receives argument into AX
    ;pop AX 
    sub AL, '0' ;obtain decimal value of the number
    
    mov BL, 5h  
    mul BL
    ;AX now has the difference in offset 
    ;between the number and 0
    ;store the offset of zero in DX 
    mov DX, offset zero 
    ;shift the offset by the difference (AL)
    add DX, AX 
    ;store the offset in the stack
    ;pop BX
    ;push DX
    ;push BX
    ret
get_number_morse ENDP 

    
beep_func PROC
    ;DX holds the offset of the morse rep'n of the char
    mov BX, DX
    mov CX, 0
    this_loop:
        ;is char dot or dash? 
        mov DX, '-' 
        ;mov BX, X
        ;pop BX ;retrieve the offset  
        mov AX, [BX]
        mov AH, 0
        cmp DX, AX
        je dash 
        ;jne dot_or_asterisk
        ;at this point it is either a dot or an asterisk
        mov DX, '.'
        cmp DX, AX
        jne end_of_charachter
        dot:
        ;beep once for dot
        ;push BX ;save char's morse offset  
        PUTC 2Eh ;print dot on screen
        mov AH, 2h
        mov DX, 07d       
        int 21h 
        
        jmp end_of_loop
             
        dash: 
        ;beep twice for dash 
        ;push BX ;save char's morse offset 
        PUTC 2Dh ;print dash on screen
        mov AH, 2h
        mov DX, 07d 
        int 21h 
        mov AH, 2h
        mov DX, 07d
        int 21h
        
        end_of_loop:
        push BX ;save offset since the next function (delay_200) uses BX
        call delay_200
        pop BX  ;restore offset 
        inc CX
        inc BX
        ;push BX
        ;mov pos, CX
        cmp CX,4d
        jle this_loop
        ;we're through with the beeps
        
        end_of_charachter:
        ;pop DX 
        ;pop DX
        
    ret
beep_func ENDP 


read_string PROC 
     ;push DI
     mov DI, 2 ;initialize DI to the index of the first letter in the string      
     string_loop:
        ;save char at i (CX)  
        mov AX, 0 ;clear AX
        mov AL, user_input[DI]
        ;check if the charachter is a letter or a string 
        cmp AL, 41h 
        
        jl number_or_space
        
        ;at this point it is a letter
        ;send to upper case 
        AND AL, 0DFh
        call get_letter_morse
        ;DX now holds the offset of the character's morse
        ;push DX;save offset in stack 
               
        ;do the BEEP!
        call beep_func 
        jmp end_of_char
        
        number_or_space:
        mov AX, 0 ;clear AX
        mov AL, user_input[DI]
        ;check if the charachter is a number or a space 
        cmp AL, 30h  
        
        jl space_char 
        
        ;at this point it is a number
        call get_number_morse
        ;DX now holds the offset of the number's morse
        ;push DX ;save the offset in the stack  
        
        ;do the BEEP!
        call beep_func
        jmp end_of_char
        
        end_of_char:
        ;PUTC 20h
        mov AH, 2h
        mov DX, 20h
        int 21h 
        call delay_500 ;delay for 0.5s between letters
        jmp mwisho
        
        space_char:
        ;PUTC 20h
        ;PUTC 20h
        mov AH, 2h
        mov DX, 20h
        int 21h
        mov AH, 2h
        mov DX, 20h
        int 21h
        call delay_1000 ;delay 1s between words
        
        mwisho:
        inc DI ;DI holds the index of the current charachter in user_input string   
        mov BX, 0
        mov BL, user_input[1] 
        ;BL should hold the length of the word
        ;this is also the index of the last charachter entered 
        add BL, 1
        cmp DI, BX
        jle string_loop 
        ;pop DI
     ret
read_string ENDP

 
delay_200 PROC ;used between beep and dash
    mov BX, CX    
    mov CX, 0x3h
    mov DX, 0x0D40h
    mov AH, 0x86h 
    mov CX, BX  
    int 15h
    ret
delay_200 ENDP

delay_500 PROC ;will be used between letters   
    mov BX, CX 
    mov CX, 0x7h
    mov DX, 0xA120h
    mov AH, 0x86h
    mov CX, BX   
    int 15h
    ret
delay_500 ENDP

delay_1000 PROC ;will be used between words 
    mov BX, CX   
    mov CX, 0xFh
    mov DX, 0x4240h
    mov AH, 0x86h
    mov CX, BX   
    int 15h
    ret
delay_1000 ENDP 
           
           
;the following function will delay the number of milliseconds in AX when called           
delay PROC ;value will be passed into AX in milliseconds 
    mov BX, 1000d
    mul BX
    mov CX, DX
    mov DX, AX
    mov AH, 0x86h
    int 15h
    ret
delay ENDP