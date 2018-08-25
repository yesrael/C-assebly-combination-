        global printer
        extern resume
        extern CORS, WorldWidth, WorldLength, debug

        ;; /usr/include/asm/unistd_32.h
sys_write:      equ 4
stdout:         equ 1
EOS:            equ 0
NEWLINE:        equ 10
SPACE:          equ 32
SINGLE_CHAR     equ 1

section .data

DEC_VALUE:      db "%d"
EOL:            db NEWLINE
EOF:            db EOS
EMPTY:          db SPACE

section .bss
array_size:     resd 1
address:        resd 1
counter:        resd 1
temp            resb 1
even_line:           resb 1

section .text

printer:
        mov     eax, 0                  ; Initialize row counter
        mov     ecx, 0                  ; Initialize column counter
        mov     al, byte [WorldLength]  ; Get num of rows
        mov     cl, byte [WorldWidth]   ; Get num of columns
        mul     cl                      ; Perform rows*columns
        mov     dword [array_size], eax ; Store the number of cells
        mov     eax, dword [CORS]       ; Get the start address of the array
        inc     eax                     ; Increase eax by 2
        inc     eax                     ; so we reach to the first cell
        mov     dword [address], eax    ; Store the Initial address
        mov     dword [counter], 0      ; Initialize counter
        mov     dword [even_line], 1

.print_loop:
        cmp     dword [array_size], 0   ; Check if we finished to iterate over the array
        je      .finish                 ;
        mov     ecx, dword [address]    ; Get current address at the array
        mov     eax, 0                  ; Initialize temp
        mov     al, byte [ecx]          ; Get the value at the address
        cmp     eax, 0                  ; Check if it is a dead cell
        jne     .alive                  ;

.dead:
        mov     byte [temp], '0'      ;
        jmp     .print                  ;

.alive:
        add     eax, '0'                ; Get the ascii value of the number
        mov     byte [temp], al         ; 

.print:
        mov     eax, sys_write          ;
        mov     ebx, stdout             ;
        mov     ecx, temp               ;
        mov     edx, SINGLE_CHAR        ;
        int     80h                     ;
        
        
.print_space:
        mov     byte [temp], SPACE 
        mov     eax, sys_write          ;
        mov     ebx, stdout             ;
        mov     ecx, temp               ;
        mov     edx, SINGLE_CHAR        ;
        int     80h  

.checks:
        inc     dword [address]         ; Increase address by 1
        dec     dword [array_size]      ; Decrease array size by 1
        inc     dword [counter]         ; Increase counter
        mov     eax, 0                  ; 
        mov     al, byte [WorldWidth]   ;
        cmp     dword [counter], eax    ; Check if we ended one line
        jl      .print_loop             ;

.new_line:
        mov     dword [counter], 0      ; Initialize counter
        mov     eax, sys_write          ;
        mov     ebx, stdout             ;
        mov     ecx, EOL                ;
        mov     edx, SINGLE_CHAR        ;
        int     80h                     ;
        cmp     dword [even_line], 1
        jne     .prepare_for_even_line             ;
        mov     byte [temp], SPACE      ; print space in the begining of even line
        mov     eax, sys_write          ;
        mov     ebx, stdout             ;
        mov     ecx, temp               ;
        mov     edx, SINGLE_CHAR        ;
        int     80h 
        mov     dword [even_line], 0
        jmp     .print_loop 
        
.prepare_for_even_line:
        mov     dword [even_line], 1
        jmp     .print_loop

.finish:
;        mov     eax, sys_write          ;
;        mov     ebx, stdout             ;
;        mov     ecx, EOL                ;
;        mov     edx, SINGLE_CHAR        ;
;        int     80h                     ;

        xor ebx, ebx
        call resume                     ; resume scheduler
        cmp byte [debug], 1
        JNE printer
        ret
        