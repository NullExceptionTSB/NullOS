;NSAB, NullException's Shitty Assembly Bootloader
;100% not copied from brokenthorn


;Please let this work

; =======================================================
; A random guy's edit:
; some comments to make this be understood.
; All my comments that are not original will be marked by
; > "comment"
; =======================================================

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
bsVolumeLabel: 	        DB "GAYLOADER  " ; > lol
bsFileSystem: 	        DB "FAT12   "

;Functions start
;===============
TextOut:
;I don't know what i'm doing at all
;Update: Now I know what i'm doing kinda

  ; > first we load into AL the byte at which the SI register
  ; > is pointing at.
  ; > for instance, lodsb is the same as doing:
  ; >  mov al, byte[si]
  ; >  inc si
  ; > so lodsb is just a helper opcode.
  lodsb
  ; > With an or operator, at least A SINGLE bit needs to be on
  ; > to error it out.
  ; > if no "error", all the bits are zero.
  or al, al ;al = current character
  ; > if no "error", zero, so end of string, so jump to the ending label
  jz TextoutEnd ;If the next character is nool, jump to TextoutEnd
  ; > Else print it
  ; > As we are so lazy, we'll let the BIOS do all work for us
  ; > with ah = 0x0E we are telling it that we want the "teletype" output
  ; > service of interrupt 0x10 (the IDT is loaded by default by the BIOS)
  ; > so when we interrupt the BIOS will know what to do
  ; > (in 0x0E 0x10 mode, the BIOS stores the char to print in al, and that's
  ; > exacly where we have our char so its fine)
  ; > For a full list of graphic services: https://en.wikipedia.org/wiki/INT_10H
  mov ah, 0eh ;gib char pls
  ; > Actual interruption
  int 10h ;Interrupt call
  jmp TextOut ;We want to repeat the function until complete
  
  
TextoutEnd:
  ; > Basically the "return;" function in C
  ret ;Assembly way of saying "Exit"
  
  
SafeHalt:
  cli ; > without this, you are not really halting, as an interrupt could stop the halt and
      ; > jump to the IDT entry to where that int is stored.
      ; > so before halting we disable interrupts first.
  jmp SafeHalt
  
;=============
;Functions end




bldr:
  cli ; Disable interrupts
 
  ; > Here you are setting up all the segments to a proper position
  ; > You should place them to where the bootsector is loaded, however,
  ; > this should be fine for now
  xor ax, ax ;Zero out AX
  mov ds, ax ;I don't know what this does
  mov es, ax ;I don't know what this does either
  
  ; > TODO: Reset CS with a long jump (i'll let you do this)
  
  ; > !! IMPORTANT !!
  sti
  ; > You disabled interrupts before, so for textout to work
  ; > you need to reenable them!
  
  ; > here you are phyisically appending Test(character null) to the file
  ; > do it after the halt, or else the CPU will think they are instructions
  ; > and execute the opcode "T" then the opcode "e" then the opcode "s" etc.
  ; > we don't know what they do, but it is definitely not what we want...
  ;   msg db "Test", 0 ;set message, I don't know what the fuck i'm doing here
  mov si, msg ;gib program message ; > you are setting SI to the phyisical address where this message is in (the assembler will translate "msg" to the actual number it is)
  call TextOut ;Output text
  
  jmp $ ; < even safer halt
  ;call SafeHalt ;Halt without killing the CPU	
  
  ; so we'll put here out message
  msg db "Test", 0
  
  times 510 - ($-$$) db 0 ;Zero out the rest of the program, except for the code. The bootloader is 512 bytes after all
  
  dw 0xAA55 ;Boot signature
  
  
  ;Temporarily disabled :: sti ;Exit and enable interrupts
  
  
  
  
  
  

  
  
  
  
  
  
  
  
  
  
  ; > why are you even reading this?
  ; > did you though there would be easter eggs down here or smthng?
  
  
  
  ; > NOPE
