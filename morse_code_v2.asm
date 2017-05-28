;Morse code generator source code
;
;
;INSTRUCTIONS:
;1. Copy "morse_characters.txt" file to C:\emu8086\MyBuild\ 
;2. ALL input should be alphanumeric.
;3. Input is case insensitive. a == A
;
;
;ENJOY!
data segment
    file_name db "morse_characters.txt", 0
    file_path db "C:\emu8086\MyBuild\" 
    error_message db "Error Occured. File may be missing or cannot be read.",10,13,"$"   
    file_handle dw ?
    data_offset dw ? 
    file_data db 255,?,255 dup(?)
    msg1 db "Welcome to morse code generator.",10,13,"$"  
    msg2 db 10,13,"Letters will be seperated by a single space",10,13,"Words will be seperated by 2 spaces",10,13,10,13,"$"
    msg3 db 10,13,"Thank you! $"
    prompt1 db 10,13,"Enter the alphanumeric string you want to convert:",10,13,10,13,"$"
    prompt2 db 10,13,10,13,"Would you like to try again? (Y/N): $"
    user_input db 50,?,50 dup('') 
ends

stack segment
    dw   128  dup(0)
ends
include "emu8086.inc"
code segment
initialize:
    ; set segment registers:
    mov AX, data
    mov DS, AX   ;data segment
    mov ES, AX   ;extra segment

    ;set current directory 
    mov AH, 3Bh
    lea DX, file_path
    int 21h 
    
    ;open the file 
    mov AL, 2    ;AL stores the command 2=read/write
    lea DX, file_name
    mov AH, 3Dh  ;Dos interrupt routine for opening a file
    int 21h
    
    jc error     ;CF is set to 1 in case there's an error in opening the file
    
    mov file_handle, AX ;ISR returns file handle in ax
    
    ;read data from file
    mov CX, 252d ;cx stores the number of bytes you want to read
                 ;(26 + 10) x 7
                 ;e.g A:.-***, 1:.----
                 
    mov BX, file_handle  ;file handle is stored in BX for the ISR (Interrupt Service Routine)
    mov AH, 3Fh          ;interrupt routine for reading a file
    int 21h 
    
    jc error     ;CF is set to 1 in case there's an error in opening the file
    
    ;data is stored in DS:DX
    ;errors are indicated in the CF
      
    mov data_offset, DX  ;save data offset 
    
    ;close file. It's good practise
    mov BX, file_handle
    mov AH, 3Eh
    int 21h 
    jmp begin:
    
    error: 
    ;display error message
    mov AH, 09h
    lea DX, error_message 
    int 21h
    jmp asanti 
    
    begin:
    ;display welcome message     
    mov AH, 9
    lea DX, msg1 
    int 21h
    
    mwanzo: 
    ;display first prompt
    mov AH, 9
    lea DX, prompt1
    int 21h 
   
    ;read input
    mov AH, 0Ah
    lea DX, user_input 
    int 21h
    
    PUTC 10D
    PUTC 13D
    
    ;display instructional message
    mov AH, 9
    lea DX, msg2
    int 21h  
    
    ;read_string funtion will go through user input and convert it into morse
    call read_string
    
    ;display final prompt
    mov AH, 9
    lea DX, prompt2
    int 21h
    
    ;read user input
    mov AH, 1h
    int 21h
    ;char is stored in AL
    
    ;send to upper case
    AND AL, 0DFh       
    cmp AL, 'Y'
    ;at this point user wants to retry
    je mwanzo
    
    asanti:
    ;display thank you message
    mov AH, 9
    lea DX, msg3 
    int 21h
    
    mov AX, 1200d
    call delay ;delay function will delay the value in AX. In milliseconds
               ;1s = 1000 milliseconds
    jmp terminate

;this function returns the morse offset 
;of the letter in AX            
get_letter_morse PROC
    ;receives argument in AX 
    ;pop AX
    sub AL, 'A'
    ;AL now has the difference 
    ;between the letter and A
    mov BL, 7h  
    mul BL
    ;AX now has the difference in offset 
    ;between the letter and letter A
    ;store the offset of the file in DX 
    mov DX, data_offset 
    ;shift the offset by the difference (AL)
    add DX, AX  
    add DX, 2 ;to skip letter and colon (E:-****) 
    ret
get_letter_morse ENDP
    
;the following function returns 
;the morse offset of the number in AX       
get_number_morse PROC 
    ;receives argument into AX
    ;pop AX 
    sub AL, '0' ;obtain decimal value of the number
    
    mov BL, 7h  
    mul BL
    ;AX now has the difference in offset 
    ;between the number and 0
    ;store the offset of zero in DX 
    mov DX, data_offset  
    
    add DX, 182d  ;set starting point to 0:-----
         
    ;shift the offset by the difference (AL)
    add DX, AX
    add DX, 2 ;to skip number and colon (2:..---) 
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
        PUTC 2Eh ;print dot on screen
        mov AH, 2h
        mov DX, 07d       
        int 21h 
        
        jmp end_of_loop
             
        dash: 
        ;beep twice for dash 
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
        cmp CX,4d
        jle this_loop
        ;we're through with the beeps
        
        end_of_charachter:
        
    ret
beep_func ENDP 


read_string PROC 
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
        ;put one space to seperate letters
        mov AH, 2h
        mov DX, 20h
        int 21h 
        
        call delay_500 ;delay for 0.5s between letters
        jmp mwisho
        
        space_char:
        ;put two spaces to seperate words
        mov AH, 2h
        mov DX, 20h
        int 21h
        mov AH, 2h
        mov DX, 20h
        int 21h
        
        call delay_1000 ;delay 1s between words
        
        mwisho:
        inc DI ;DI holds the index of the current charachter in user_input string 
               ;shift it to the next char by incrementing DI
        mov BX, 0
        mov BL, user_input[1] 
        ;BL should hold the length of the word
        ;this is also the index of the last charachter entered 
        add BL, 1
        cmp DI, BX
        jle string_loop 
     ret
read_string ENDP

 
delay_200 PROC ;used between beep and dash
    mov BX, CX    
    mov CX, 0x3
    mov DX, 0x0D40
    mov AH, 0x86 
    mov CX, BX  
    int 15h
    ret
delay_200 ENDP

delay_500 PROC ;will be used between letters   
    mov BX, CX 
    mov CX, 0x7
    mov DX, 0xA120
    mov AH, 0x86
    mov CX, BX   
    int 15h
    ret
delay_500 ENDP

delay_1000 PROC ;will be used between words 
    mov BX, CX   
    mov CX, 0xF
    mov DX, 0x4240
    mov AH, 0x86
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
    mov AH, 0x86
    int 15h
    ret
delay ENDP
    ;;;;;
    
terminate:    
         
ends

end initialize ; set entry point and stop the assembler.
               ;main function return 
