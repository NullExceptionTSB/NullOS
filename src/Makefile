#	/=============================================\
#	|!RUN ONLY FROM IN THE ROOT PROJECT DIRECTORY!|
#	\=============================================/

CC = gcc
CL = ld
CA = -Iinclude -masm=intel -Wno-pedantic -Wall -Wextra -m32 -fno-pie -nodefaultlibs -nostartfiles -nostdlib
ASM = nasm
MNTPNT = /mnt

makeos:
	#==STEP: compile/assemble/link the binaries==
	$(ASM) -f bin bootloader/stage1/stage1.asm -o ./s1.bin
	$(ASM) -f bin bootloader/soareldr/soareldr-stage2.asm -o ./SOARELDR.SYS
	$(ASM) -f coff kernel/hal/asm_abstraction.asm -o ./halasm.o
	$(CC) kernel/hal/hal.c $(CA) -c -o hal.o
	$(CC) kernel/hal/handlers.c $(CA) -c -o halhandlers.o
	$(CC) kernel/nullkrnl/nullkrnl.c $(CA) -c -o nullkrnl.o
	$(CC) kernel/nullkrnl/vga.c $(CA) -c -o vga.o
	$(CC) stdlib/* $(CA) -c -o stdlib.o
	$(CL) hal.o nullkrnl.o vga.o stdlib.o halhandlers.o halasm.o --oformat=pei-i386 -m i386pe --image-base 0x100000 -e NklEntry -o NULLKRNL.SYE
	echo "This file is currently a placeholder because the features it's dependent on haven't been implemented" >> placeholderdata
	cp placeholderdata HAL.SYS
	#==STEP: clean up==
	rm placeholderdata
	#kernel
	rm stdlib.o
	rm vga.o
	rm nullkrnl.o
	#hardware abstraction layer
	rm hal.o
	rm halasm.o
	rm halhandlers.o
	#==STEP: build floppy image==
	#==if this step fails, try running "make makeutils"==
	utils/mkimg -ov boot.flp -i s1.bin
	sudo mount boot.flp $(MNTPNT)
	sudo cp SOARELDR.SYS $(MNTPNT)/SOARELDR.SYS
	sudo cp HAL.SYS $(MNTPNT)/HAL.SYS
	sudo cp NULLKRNL.SYE $(MNTPNT)/NULLKRNL.SYE
	sudo umount $(MNTPNT)
	#==STEP: run==
	kvm -fda boot.flp -monitor stdio -no-reboot -no-shutdown -m 256M

makeutils:
	#==UTIL: mkimg==
	$(CC) utils/mkimg.c -o utils/mkimg

clean:
	rm SOARELDR.SYS
	rm HAL.SYS
	rm NULLKRNL.SYE
	rm s1.bin
	rm boot.flp
	rm utils/mkimg
run:
	kvm -fda boot.flp -monitor stdio
