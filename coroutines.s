;;; This is a simplified co-routines implementation:
;;; CORS contains just stack tops, and we always work
;;; with co-routine indexes.
        global init_co, start_co, end_co, resume
        global _start, array_element_address, updateRegister
        global WorldLength, WorldWidth, CORS, debug
          extern scheduler, printer
        extern atoi, fopen, fclose, fgetc, handleCell, malloc, free, printf

maxcors:        equ 60*60+2         ; maximum number of co-routines
stacksz:        equ 16*1024     ; per-co-routine stack size

section .rodata
        parameters_error: db "Error: Insufficent number of parameters", 10, 0
        read_only: db "r"
        address: db "%p", 10, 0
        value: db "%d", 10, 0
        
        
section .bss

stacks: resb maxcors * stacksz  ; co-routine stacks
cors:   resd maxcors            ; simply an array with co-routine stack tops
curr:   resd 1                  ; current co-routine
origsp: resd 1                  ; original stack top
tmp:    resd 1                  ; temporary value
 CORS:           resd    1; Will hold the address of the start of the array
        WorldLength:    resb    1; 
        WorldWidth:     resb    1;
        Generations:    resb    1;
        PrintCycle      resb    1;
        FileName        resd    1;
        File            resd    1;
        RowCounter      resb    1;
        ColumnCounter   resb    1;
        temp            resd    1;
        single_char     resb    1;
        debug           resb    1;

        ;; /usr/include/asm/unistd_32.h
sys_exit:       equ   1
sys_write       equ   4
stdout          equ   1
scheduler_id:   equ   0
printer_id:     equ   1
parameters_num  equ   6
length          equ   41
eof             equ   0
new_line        equ   10
shit            equ   13
one             equ   '1'
space           equ   ' '


section .data
     	; ------------------ format string ------------------ ;
        debug_start                                                     db      "=============debug============", new_line, eof
        input_fomat                                                     db      "Input: ", new_line, eof
	file_name_format						db	new_line, "File name: %s", new_line, eof					; 
	length_format						        db	"length: %s", new_line, eof					; 
	width_format						        db	"width: %s", new_line, eof					; 
	Generations_format						        db	"Generations <t>: %s", new_line, eof					; 
	steps_format						        db	"steps <k>: %s", new_line, eof					; 
        debug_end                                                       db      "==============================", new_line, eof

section .text

_start:
        enter   0, 0
        cmp     dword [ebp+4], parameters_num   ; Check if we received all parameters
        jl     .error                           ;
 	mov ebx, dword [ebp+12]
	cmp byte[ebx],'-'
        JNE .get_parameters_witout_debug 
        cmp byte[ebx+1],'d'
        JNE .get_parameters_witout_debug         
        mov dword[debug],1
.get_parameters_with_debug: 
        mov     dword [CORS], 0                 ; Initialize
        mov     eax, dword [ebp+16]             ; Get the file name 
        mov     dword [FileName], eax           ; Store it
        push    dword [ebp+20]                  ; Push the length of the array to the stack
        call    atoi                            ; Turn in into number
        add     esp,4                           ; Clean stack after call
        mov     byte [WorldLength], al          ; Store the array length
        push    dword [ebp+24]                  ; Push the width of the array to the stack
        call    atoi                            ; Turn in into number
        add     esp, 4                          ; Clean stack after call
        mov     byte [WorldWidth], al           ; Store the array width
        push    dword [ebp+28]                  ; Push 't' to the stack
        call    atoi                            ; Turn in into number
        add     esp, 4                          ; Clean stack after call
        mov     byte [Generations], al          ; Store 't'
        push    dword [ebp+32]                  ; Push 'k' into the stack
        call    atoi                            ; Turn in into number
        add     esp, 4                          ; Clean stack after call
        mov     byte [PrintCycle], al           ; Store 'k' 
        jmp     .initialize_board

.get_parameters_witout_debug:
        mov    dword [debug], 0              ; no debug flag 
        mov     dword [CORS], 0                 ; Initialize
        mov     eax, dword [ebp+12]             ; Get the file name 
        mov     dword [FileName], eax           ; Store it
        push    dword [ebp+16]                  ; Push the length of the array to the stack
        call    atoi                            ; Turn in into number
        add     esp,4                           ; Clean stack after call
        mov     byte [WorldLength], al          ; Store the array length
        push    dword [ebp+20]                  ; Push the width of the array to the stack
        call    atoi                            ; Turn in into number
        add     esp, 4                          ; Clean stack after call
        mov     byte [WorldWidth], al           ; Store the array width
        push    dword [ebp+24]                  ; Push 't' to the stack
        call    atoi                            ; Turn in into number
        add     esp, 4                          ; Clean stack after call
        mov     byte [Generations], al          ; Store 't'
        push    dword [ebp+28]                  ; Push 'k' into the stack
        call    atoi                            ; Turn in into number
        add     esp, 4                          ; Clean stack after call
        mov     byte [PrintCycle], al           ; Store 'k' 
        jmp     .initialize_board
        
.print_debug_mode:
        push  debug_start
        call printf
        add esp, 4
        push input_fomat
        call printf
        add esp, 4
        call printer
        mov dword[debug],0
        push dword [FileName]
        push  file_name_format
        call printf
        add esp, 8
        push    dword [ebp+20] 
        push  length_format
        call printf
        add esp, 8
         push    dword [ebp+24] 
        push  width_format
        call printf
        add esp, 8
        push    dword [ebp+28] 
        push  Generations_format
        call printf
        add esp, 8
        push    dword [ebp+32] 
        push  steps_format
        call printf
        add esp, 8
        push  debug_end
        call printf
        add esp, 4
        jmp .initialize_scheduler

.initialize_board:
        mov     eax, 0                          ;
        mov     al, byte [WorldLength]          ;
        mov     ecx, 0                          ;
        mov     cl, byte [WorldWidth]           ;
        mul     cl                              ;
        add     eax, 2                          ; Get the number of cells + 2
        push    eax                             ;
        call    malloc                          ;
        add     esp, 4                          ;
        mov     dword [CORS], eax               ; Save the allocated memory

        push    read_only                       ;
        push    dword [FileName]                ;
        call    fopen                           ;
        add     esp, 8                          ;
        mov     dword [File], eax               ; Save the return value of fopen
        mov     byte [RowCounter], 0            ;
        mov     byte [ColumnCounter], 0         ;
        mov     byte [single_char], 0           ;

.read_row:
        mov     ebx, 0
        mov     bl, byte [RowCounter]           ;
        cmp     bl, byte [WorldLength]          ; Check if we finished to iterate over all the rows
        je      .close_file                     ;

        cmp     byte [single_char], new_line    ;
        je      .read_column                         ;
        cmp     byte [single_char], shit        ;
        je      .ignore                         ;
        cmp     byte [single_char], space        ;
        je      .ignore
        jmp     .read_column
.ignore:
        push    dword [File]                    ;
        call    fgetc                           ; Ignore new lines and other not important chars
        add     esp, 4                          ;
        mov     byte [single_char], al          ;
.read_column:
        mov     ebx, 0                          ; 
        mov     bl, byte [ColumnCounter]        ;
        cmp     bl, byte [WorldWidth]           ; Check if we finised to iterate over one row
        je      .end_of_line                    ;

        mov     eax, 0                          ;
        mov     al, byte [RowCounter]           ;
        mov     ecx, 0                          ;
        mov     cl, byte [WorldWidth]           ;
        mul     cl                              ;
        mov     ecx, 0                          ;
        mov     cl, byte [ColumnCounter]        ;
        add     eax, ecx                        ;
        add     eax, 2                          ;
        mov     ebx, dword [CORS]               ;
        add     ebx, eax                        ; Get the current location in the array
        push    ebx                             ;

        push    dword [File]                    ;
        call    fgetc                           ; Read the next character
        add     esp, 4                          ;
        mov     byte [single_char], al          ;
        pop     ebx                             ;
        
        cmp     byte [single_char], space        ;
        je      .read_column
        cmp     byte [single_char], one         ; Check what is the next char
        jne     .empty                          ;
        mov     byte [ebx], 1                   ;
        jmp     .next_cell                      ;
.empty:
        mov     byte [ebx], 0                   ;

.next_cell:
        add     byte [ColumnCounter], 1         ; Increase column counter by 1
        jmp     .read_column                    ;

.end_of_line:
        push    dword [File]                    ;
        call    fgetc                           ;
        add     esp, 4                          ;
        mov     byte [single_char], al          ;
        cmp     byte [single_char], eof         ; Check if we've reached enf of file
        je      .close_file
        mov     byte [ColumnCounter], 0         ; Initialize column counter
        add     byte [RowCounter], 1            ; Increase by 1 row counter
        jmp     .read_row

.close_file:
        push    dword [File]                    ;
        call    fclose
        add     esp, 4
        cmp byte [debug], 1 
        je .print_debug_mode

.initialize_scheduler:
        xor     ebx, ebx                        ; scheduler is co-routine 0
        mov     edx, scheduler                  ; scheduler function is scheduler
        mov     eax, 0                          ; initialize temp
        mov     al, byte [PrintCycle]           ; Get 'k'
        mov     edi, eax                        ; Set second parameter to 'k'
        mov     eax, 0                          ; Initialize first parameter
        mov     al, byte [Generations]          ; Set first parameter to 't'     
        call    init_co                         ; initialize scheduler state

.initialize_printer:
        inc     ebx                             ; printer is co-routine 1
        mov     edx, printer                    ; The printer function is printer
        call    init_co                         ; initialize printer state

.initialize_cells:
        mov     eax, 0                          ; Initialize temp 
        mov     ecx, 0                          ; Initialize cell counter
        mov     al, byte [WorldLength]          ; Get the length of the array
        mov     cl, byte [WorldWidth]           ; Get the width of the array
        mul     cl                              ; Perform length*width
        mov     ecx, eax                        ; Move the muliply result to ecx
        mov     edx, handleCell                 ; The function of each cell is getData

.single_cell:
        cmp     ecx, 0                          ;
        je      .start                          ;
        dec     ecx                             ;
        inc     ebx                             ; Update co-routine id
        mov     edi, ebx                        ;
        mov     eax, ebx                        ;
        call    init_co                         ; Initialize cell state
        jmp     .single_cell       

.start:
        xor     ebx, ebx                        ; starting co-routine = scheduler
        call    start_co                        ; start co-routines
        jmp     .exit                           ;

.error:
        mov     eax, sys_write                  ;
        mov     ebx, stdout                     ;
        mov     ecx, parameters_error           ;
        mov     edx, length                     ;
        int     80h

.exit:
        push    dword [CORS]
        call    free
        add     esp, 4
        mov     eax, sys_exit
        xor     ebx, ebx
        int     80h

;============================================================================================

array_element_address:

        push    ebp                             ;
        mov     ebp, esp                        ;
        pushad                                  ;

        mov     ebx, dword [ebp+8]              ; Get array address
        inc     ebx                             ; The first two elements in the array 
        inc     ebx                             ; are scheduler and printer
        mov     eax, dword [ebp+16]             ; Get array width
        mov     ecx, dword [ebp+20]             ; Get 'x' location
        mul     cl                              ; Perform x*width
        mov     ecx, eax                        ; Get the result of the multiply
        mov     eax, dword [ebp+24]             ; Get 'y' location
        add     ecx, eax                        ; Now ecx contains x*width+y

.find_loop:
        cmp     ecx, 0                          ; Check if the loop should finish
        je      .finish                         ;
        dec     ecx                             ; Reduce counter by 1
        inc     ebx                             ; Increase array address
        jmp     .find_loop

.finish:
        mov     dword [temp], ebx               ;
        popad
        mov     esp, ebp                        ;
        pop     ebp                             ;
        mov     eax, dword [temp]               ; Set return value
        ret                                     ;

;================================================================================

updateRegister:

        push    ebp
        mov     ebp, esp

        mov     ebx, 0

        mov     esp, ebp
        pop     ebp
        ret



;=====================================================================================
        ;; ebx = co-routine index to initialize
        ;; edx = co-routine start
        ;; other registers will be visible to co-routine after "start_co"
init_co:
        push eax                ; save eax (on caller's stack)
		push edx
		mov edx,0
		mov eax,stacksz
        imul ebx			    ; eax = co-routine's stack offset in stacks
        pop edx
		add eax, stacks + stacksz ; eax = top of (empty) co-routine's stack
        mov [cors + ebx*4], eax ; store co-routine's stack top
        pop eax                 ; restore eax (from caller's stack)

        mov [tmp], esp          ; save caller's stack top
        mov esp, [cors + ebx*4] ; esp = co-routine's stack top

        push    eax             ; Push first parameter to the stack
        push    edi             ; Push second parameter to the stack

        push edx                ; save return address to co-routine stack
        pushf                   ; save flags
        pusha                   ; save all registers
        mov [cors + ebx*4], esp ; update co-routine's stack top

        mov esp, [tmp]          ; restore caller's stack top
        ret                     ; return to caller

        ;; ebx = co-routine index to start
start_co:
        pusha                   ; save all registers (restored in "end_co")
        mov [origsp], esp       ; save caller's stack top
        mov [curr], ebx         ; store current co-routine index
        jmp resume.cont         ; perform state-restoring part of "resume"

        ;; can be called or jumped to
end_co:
        mov esp, [origsp]       ; restore stack top of whoever called "start_co"
        popa                    ; restore all registers
        ret                     ; return to caller of "start_co"

        ;; ebx = co-routine index to switch to
resume:                         ; "call resume" pushed return address
        pushf                   ; save flags to source co-routine stack
        pusha                   ; save all registers
        xchg ebx, [curr]        ; ebx = current co-routine index
        mov [cors + ebx*4], esp ; update current co-routine's stack top
        mov ebx, [curr]         ; ebx = destination co-routine index
.cont:
        mov esp, [cors + ebx*4] ; get destination co-routine's stack top
        popa                    ; restore all registers
        popf                    ; restore flags
        ret                     ; jump to saved return address