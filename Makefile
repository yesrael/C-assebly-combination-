all: GOL

GOL:  scheduler.o printer.o coroutines.o GOL.o
	gcc -m32 -Wall -g -nostartfiles -o GOL  scheduler.o printer.o coroutines.o GOL.o

scheduler.o: scheduler.s
	nasm -g -f elf -w+all -o scheduler.o scheduler.s 

printer.o: printer.s
	nasm -g -f elf -w+all -o printer.o printer.s

coroutines.o: coroutines.s 
	nasm -g -f elf -w+all -o coroutines.o coroutines.s

GOL.o: GOL.c 
	gcc -g -Wall -m32 -ansi -c -o GOL.o GOL.c

.PHONY: clean

clean:
	rm -f *.o GOL