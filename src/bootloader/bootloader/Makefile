ASM = nasm
MNTPNT = /mnt

fullmake:
	$(ASM) stage1/stage1.asm -o ./s1.img
	$(ASM) -f bin soareldr/soareldr-stage2.asm -o ./SOARELDR.SYS
	rm boot.flp
	fat_imgen -c -f boot.flp -s s1.img
	sudo mount boot.flp $(MNTPNT)
	sudo cp SOARELDR.SYS $(MNTPNT)/SOARELDR.sys
	sudo umount $(MNTPNT)
	kvm -fda boot.flp -monitor stdio

s1make:
	$(ASM) stage1.asm -o s1.img
	fat_imgen -m -f boot.flp -s s1.img
	kvm -fda boot.flp -monitor stdio

runonly:
	kvm -fda boot.flp -monitor stdio
