;====NullException's Slightly Less Shit Bootloader====
;=====================================================
BITS 16h ;Bootloaders have to be in real mode
ORG 7c00h ;Start at sector 1

jmp Main ;Start at Main

;==BPB=Start== !!!IMPORTANT!!! THE BPB HAS TO BE BEOFRE BEFORE THE DATA SEGMENT, OTHERWISE IT WONT WORK
bpbBytesPerSector:  	DW 512
bpbSectorsPerCluster: 	DB 1
bpbReservedSectors: 	DW 1
bpbNumberOfFATs: 	DB 2
bpbRootEntries: 	DW 224
bpbTotalSectors: 	DW 2880
bpbMedia: 		DB 0xF0
bpbSectorsPerFAT: 	DW 9
bpbSectorsPerTrack: 	DW 18
bpbHeadsPerCylinder: 	DW 2
bpbHiddenSectors: 	DD 0
bpbTotalSectorsBig:     DD 0
bsDriveNumber: 	        DB 0
bsUnused: 		DB 0
bsExtBootSignature: 	DB 0x29
bsSerialNumber:	        DD 0xa0a1a2a3
bsVolumeLabel: 	        DB "MOS Floppy "
bsFileSystem: 	        DB "FAT12   "
;==BPB=End==;


%include "fat12embed.asm"


;V0.2.2 og bootloader do not steal

;====Data=START====
msg db "Running NoolOS 0.2.2",0xA,0xD,0
bootloader0 db "Resetting drive",0xA,0xD,0
bootloader1 db "Root Directory Loaded",0xA,0xD,0
done db "Executing kernel loader",0xA,0xD,0
err0 db "Read/Write Error, retry",0xA,0xD,0
fatal0 db "Disk RW error, system halted",0
fatal1 db "Kernel loader not found, system halted",0
;====Data=END======

;=Code=Start=;

Print: 
    pusha
    .MPrint:
    lodsb      ;Load SI into AL
    or         al, al ;Get current character
    jz         .PrintDone ;Is it nool ? If yes, jump to PrintDone, since it's a null terminated string.
    mov        bl, 09h ;Output the string
    mov        ah, 0eh ;Get contents of AL
    int        10h ;Interrupt call
	jc         FatalError ;Something somehow somewhere fucked up. Panic.
    jmp        .MPrint ;Loop back to print
	
    .PrintDone:
	popa
    ret ;Exit this function
	
;====Error=Handling====;

OutputRWError:	;The only thing that I dind't copy from brokenthorn or UltrasonicOS is this error handler. Am proud. Update: Had to shrink the error handler Update: Error handler now has 1 message because of space limitations™
    inc dh
	clc
    cmp dh, 5d
	jg .SetFlagA
	.SetFlagA:
	mov dh, 7d
	jmp FatalError
	
KLNF:
	mov dh, 8d
	jmp FatalError
FatalError:
    cmp dh, 7d
	je .RWFError
	cmp dh, 8d
	je .KLNFF
    jmp .Kill
	
	.KLNFF:
	mov si, fatal1
	call Print
	jmp .Kill
	
	.RWFError:
	mov si, fatal0
	call Print
	jmp .Kill
	
	.Kill:
	cli
	hlt
;====Error=Handling=End====;	
ResetDisk:
    xor ah, ah ;Sets the function for int 13h
	xor dl, dl ;drive
	int 13h
	jc OutputRWError
	ret

GetRootDir:
   mov ax, 0x1000
   mov ss, ax
   mov sp, 0xFFF0
	
   mov ax, 1d
   mov bx, 7E00h
   mov cx, 3d
   call read_sectors
   ret
Main:
    cli
	sti
    mov si, msg ;Move the string to SI
    call Print
	mov si, bootloader0
	call Print
	call ResetDisk
	call GetRootDir
	mov si, bootloader1
	call Print
	cli 
	hlt
	
datasector dw 0000h ;Needed, will be assigned by function
iName db "KRNLDR  SYS"
TIMES 510 -($ - $$) db 0
dw 0aa55h

;=Code=End=;



