        global scheduler
        extern resume, end_co, printf
        extern WorldLength, WorldWidth

section .rodata
	dec_value: 	db "%d", 10, 0
	print_ok: db "every thing is OK", 10, 0

section .bss
	temp: 	resd 	1

printer_id	equ	1

section .text

scheduler:
        pop		edi 						; Get 'k'
        pop 	edx							; Get 't'

        mov 	eax, 0						; Initialize temp
        mov 	ecx, 0						; Initialize cells counter
        mov 	al, byte [WorldLength]		; Get array length 
        mov 	cl, byte [WorldWidth] 		; Get array length 
        mul 	cl 							;
        mov 	ecx, eax					; Get the multiply result
        mov 	dword [temp], ecx 			; Store the cells number counter
        mov 	esi, 0						; Will check for print cycles

.first_loop:
		mov 	eax, 2						; Set second loop counter
		cmp 	edx, 0						; Check if t==0
		je 		.finish						;

.second_loop:
		mov		ecx, dword [temp]			; Get the cells number

.third_loop:
		mov 	ebx, ecx					;
		inc 	ebx							; Get current co-routine id
		call 	resume						; 
		inc 	esi							;
		cmp 	esi, edi					;
		jne 	.no_print					;
		mov 	ebx, printer_id 			;
		call 	resume 						;
		mov 	esi, 0 						;

.no_print: 
		loop 	.third_loop					; Repeat until we visited every cells

		dec 	eax							; 
		cmp 	eax, 0						;
		jne 	.second_loop				;
		dec 	edx							; t--
		jmp 	.first_loop					;
		
.finish:
		mov 	ebx, printer_id				;
        call 	resume             			; resume printer

        call 	end_co             			; stop co-routines