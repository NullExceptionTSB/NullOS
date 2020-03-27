#	/=============================================\
#	|!RUN ONLY FROM IN THE ROOT PROJECT DIRECTORY!|
#	\=============================================/

ASM = nasm
MNTPNT = /mnt

fullmake:
	$(ASM) -f bin bootloader/stage1/stage1.asm -o ./s1.img
	$(ASM) -f bin bootloader/soareldr/soareldr-stage2.asm -o ./SOARELDR.SYS
	$(ASM) -f bin kernel/krnlstub.asm -o ./NOOLKRNL.SYS
	rm boot.flp
	fat_imgen -c -f boot.flp -s s1.img
	sudo mount boot.flp $(MNTPNT)
	sudo cp SOARELDR.SYS $(MNTPNT)/SOARELDR.SYS
	sudo cp NOOLKRNL.SYS $(MNTPNT)/NOOLKRNL.SYS
	sudo umount $(MNTPNT)
	kvm -fda boot.flp -monitor stdio

prep:
	touch boot.flp

run:
	kvm -fda boot.flp -monitor stdio
