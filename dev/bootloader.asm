;NSAB, NullException's Shitty Assembly Bootloader
;100% not copied from brokenthorn


;Please let this work

org 0x7c00  ;Set the origin to the first sector, 0X7C00

bits 16 ;Bootloaders HAVE to be in realmode

start: jmp bldr

    ; OOO    EEEE    MM   MM ;
   ; O   O   E       M M M M  ;
  ;  O   O   EEEE    M  M  M   ;
 ;   O   O   E       M     M    ;
;     OOO    EEEE    M     M     ;
;This is just copy pasted from brokenthorn, since i'm lazy;
bpbOEM			db "NoolOS  "	;I did not copy this one tho

bpbBytesPerSector:  	DW 512
bpbSectorsPerCluster: 	DB 1
bpbReservedSectors: 	DW 1
bpbNumberOfFATs: 	    DB 2
bpbRootEntries: 	    DW 224
bpbTotalSectors: 	    DW 2880
bpbMedia: 	            DB 0xF0
bpbSectorsPerFAT: 	    DW 9
bpbSectorsPerTrack: 	DW 18
bpbHeadsPerCylinder: 	DW 2
bpbHiddenSectors: 	    DD 0
bpbTotalSectorsBig:     DD 0
bsDriveNumber: 	        DB 0
bsUnused: 	            DB 0
bsExtBootSignature: 	DB 0x29
bsSerialNumber:	        DD 0xa0a1a2a3
bsVolumeLabel: 	        DB "GAYLOADER  "
bsFileSystem: 	        DB "FAT12   "

;Functions start
;===============
TextOut:
;I don't know what i'm doing at all
;Update: Now I know what i'm doing kinda

  lodsb
  or al, al ;al = current character
  jz TextoutEnd ;If the next character is nool, jump to TextoutEnd
  mov ah, 0eh ;gib char pls  
  int 10h ;Interrupt call
  jmp TextOut ;We want to repeat the function until complete
  
  
TextoutEnd:
  ret ;Assembly way of saying "Exit"
  
  
SafeHalt:
  jmp SafeHalt
  
;=============
;Functions end




bldr:
  cli ;Clear interrupts
 
  xor ax, ax ;Zero out AX
  mov ds, ax ;I don't know what this does
  mov es, ax ;I don't know what this does either
  
  msg db "Test", 0 ;set message, I don't know what the fuck i'm doing here
  mov si, msg ;gib program message
  call TextOut ;Output text
  
  ;call SafeHalt ;Halt without killing the CPU	
  
  times 510 - ($-$$) db 0 ;Zero out the rest of the program, except for the code. The bootloader is 512 bytes after all
  
  dw 0xAA55 ;Boot signature
  
  
  ;Temporarily disabled :: sti ;Exit and enable interrupts
  
  
  
  
  
  

  