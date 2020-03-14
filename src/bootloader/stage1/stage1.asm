bits 16
org 0x7C00  
jmp short Main
nop
times 3-($-$$) dd 0
OEMLabel               db "SOARE   "
BytesPerSector         dw 512d        
SectorsPerCluster      db 1             
ReservedSectors        dw 1             ;dw 4  WILL NOT WORK! THERE WILL NOT BE ENOUGH SPACE FOR 224 ROOT ENTRIES!
FATCount               db 2             ;number of FATs
RootDirEntryCount      dw 224           ;ammount of maximum root directory entries
TotalSectors           dw 2880          
MediaType              db 0xF0          ;media descriptor byte
SectorsPerFAT          dw 9          
SectorsPerTrack        dw 18             
HeadCount              dw 2             ;number of r/w heads
HiddenSectorCount      dd 0             ;number of hidden sectors
LargeSectorCount       dd 0             ;number of sectors larger then 32 MB
BootDriveNum           db 0             ;drive which holds the boot sector
Reserved               db 0
Signature              db 0x29         ;drive signature, 41d = floppy
SerialNumber           dd 0xDEADBEEF   ;disk serial, little endian for DEADBEEF
VolumeLabel            db "NOOLOSSOARE"
FileSystem             db "FAT12   "    

Main:
;clear screen
    mov ax, 2
    int 10h
;print message 1
    mov si, msg
    call Print
;reset floppy
    xor ax, ax
    mov dl, BYTE [BootDriveNum]
    int 13h
;prepare buffer
    mov ax, 0x07E0
    mov es, ax
    xor bx, bx
;start loading root directory
;calculate size of root cirectory in sectors
    mov ax, 32 ;32 bytes per entry
    mul WORD [RootDirEntryCount] ;times the number of entries
    div WORD [BytesPerSector] ;divided by the ammount of bytes per sector
    xor dx, dx
    mov cx, ax 
;calculate the start of the root directory in LBA (converted to CHS in disk.asm)
    movzx ax, BYTE [FATCount]
    mul WORD [SectorsPerFAT]
    add ax, WORD [ReservedSectors]
    ;save this value for later
    mov dx, cx
    add dx, ax
    mov [DiskDataStartLBA], dx
;load root dir into 07E0:0000 (0x7E00) from boot disk, buffer set above
    movzx dx, BYTE [BootDriveNum]
    call LoadSectors ;disk.asm
    jc HALT
;let's find the file
    FindFile:
    push cx
    mov cx, 11 ;length of FAT12 file names
    mov si, filename
    push di
    rep cmpsb
    pop di
    je FileFound
    pop cx
    add di, 32
    loop FindFile
    jmp HALT
    FileFound:
    mov si, msg2
    call Print
;found the file, store the starting cluster
    mov dx, WORD [es:di + 26]
    mov [startingCluster], dx
;size of ONE fat, the second FAT is a copy of the first so it doesn't matter
    mov cx, [SectorsPerFAT]
    xor ax, ax
;start right after reserved sectors
    add ax, [ReservedSectors]
    xor bx, bx ;buffer is STILL @ 0x7E00
    movzx dx, BYTE [BootDriveNum]
    call LoadSectors
    jc HALT
;calculate how many bytes there are per cluster
    movzx ax, BYTE [SectorsPerCluster]
    mul WORD [BytesPerSector]
    mov [BytesPerCluster], ax
    xor dx, dx
;now the hard part, using FAT12. i'll preface this by saying FUCK FAT12
;start by setting the buffer to 0x500, the place SOARELDR expects to be loaded
    mov ax, 0x050
    mov es, ax
    mov ax, WORD [startingCluster]
;*sigh*
LoadClusters:
    call LoadCluster
;get next cluster
;test if it's odd or even
    mov cx, ax
    mov di, ax
    shr di, 1
    add di, cx
    push es
    mov cx, 0x7E0
    mov es, cx
    mov dx, [es:di]
    pop es
    
    test ax, 1
    jnz .OddCluster
    .EvenCluster:
    and dx, 0x0FFF
    jmp .PostOddEven
    
    .OddCluster:
    shr dx, 4
    
    .PostOddEven:
;increment buffer offset
    add bx, [BytesPerCluster]
;prepare for next iteration
    mov ax, dx
    cmp dx, 0x0FF0
    jb LoadClusters
;SOARELDR loaded @ 0x0000:0x0500, print message and jump
    mov si, msg3
    call Print
    jmp 0x0500

%include 'stage1/disk.asm' 
Print:
    lodsb
    or al, al   
    jz .printEnd
    mov ah, 0Eh
    int 10h
    jmp Print
        .printEnd:
        ret

;halt at end of code
HALT:
    mov si, err
    call Print
    cli
    hlt
;Data
msg db "Welcome to NoolOS-SOARE",0xA,0xD,0
msg2 db "Found SOARELDR",0xA,0xD,0
msg3 db "Loaded SOARELDR, Staging",0
err db "E: System halted",0

startingCluster dw 0
filename db "SOARELDRSYS"
DiskDataStartLBA dw 0
BytesPerCluster dw 0
times 510-($-$$) db 0
dw 0xAA55