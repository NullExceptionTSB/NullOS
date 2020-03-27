;This will be a COM program but is currently not segmented
;this won't be a com program and will use a custom format
;actually this will just be a flat binary forever to make things easier
%define ROOT_DIRECTORY_SEGMENT 0x800
%define FAT_SEGMENT 0x4000


org 0x500
bits 16

SldEntry:
mov si, prepkrnl
call SldPrint16
mov si, shineon
call SldPrint16
;load kernel
;memcpy BPB from stage 1
pusha

mov ax, 0x07C0
push ds
push es
push es
pop ds
mov es, ax
xor ax, ax ;reset floppy
int 13h
;memcpy

mov cx, 0x3D
CopyBPB:
mov bx, cx
mov di, BPBJMP
mov dx, ds
shl dx, 4
sub di, dx
add di, cx
mov dl, BYTE [es:bx]
mov BYTE [ds:di], dl
loop CopyBPB
pop es
pop ds
popa

;mov ax, 0x050
;mov ds, ax

push dx
movzx ax, BYTE [SectorsPerCluster]
mul WORD [BytesPerSector]
mov [BytesPerCluster], ax
pop dx

;loaded the BPB, now load the root directory
;yeah most of this is copypasted from stage 1, deal with it
push es
call SldLoadRootDirectory
call SldLoadFAT

pop es
push ds
xor bx, bx

push es

;NOOLKRNL.SYS -> 0x80000
mov ax, 0x8000
mov es, ax
mov si, fn_NOOLKRNL
call SldLoadFile
jc SldPrint_FileLoadFailed

;set up the GDT
cli
pusha
lgdt [__GDTPTR]
popa

;switch to pmode
mov eax, cr0
or eax, 1
mov cr0, eax
jmp 0x08:Sld32Entry
jmp SldHalt

SldPrint_FileLoadFailed:
    push si
    mov si, failedtoload
    call SldPrint16
    pop si
    mov cx, 8
    mov ah, 0Eh
    .PrintFilename:
    mov al, BYTE [si]
    int 10h
    inc si
    loop .PrintFilename
    jc .PostExtension
    mov al, 2eh
    int 10h
    mov cx, 3
    stc
    jmp .PrintFilename
    .PostExtension:
    mov al, 0Ah
    int 10h
    mov al, 0Dh
    int 10h
    jmp SldHalt

SldPrint16:
    lodsb
    or al, al
    jz .print16End
    mov ah, 0Eh
    int 10h
    jmp SldPrint16
        .print16End:
        ret

;IN:
;AX = LBA
;OUT:
;CHS variables = CHS

;cylinders  = LBA / (sectors per track * head count)
;heads      = (LBA / sectors per track) % head count
;sectors    = (LBA % sectors per track) + 1
LBA2CHS:
push dx
xor dx, dx
div WORD [SectorsPerTrack]
inc dl
mov [CHS_sectors], dl
xor dx, dx
div WORD [HeadCount]
mov [CHS_heads], dl
mov [CHS_cylinders], al
pop dx
ret

;IN: 
;AX = LBA
;DL = drive
;ES:BX = buffer segment:offset
;OUT:
;CF = 1 if error
SldLoadSector:
pusha
call LBA2CHS
mov ah, 2
mov al, 1
mov ch, [CHS_cylinders]
mov cl, [CHS_sectors]
mov dh, [CHS_heads]
clc
int 13h
popa
ret

;IN:
;AX = LBA
;CX = sector count
;DL = drive
;ES:BX = buffer segment:offset
;OUT:
;CF = 1 if error
;CX = sectors actually read

SldLoadSectors:
pusha
    .readLoop:
    clc
    call SldLoadSector
    inc ax
    add bx, 512
    jc .done
    loop .readLoop
    jmp .done
    .done:
    popa
    ret

SldLoadCluster:
pusha
sub ax, 2
;now, nobody bothered to tell me this but the fucking shit's base address is after the root directory. on one hand
;i'm stupid for not realising it myself, on the other, fuck you.
add ax, [DiskDataStartLBA]
mov dl, [BootDriveNum]
movzx cx, BYTE [SectorsPerCluster] 
call SldLoadSectors
popa
ret

;also initializes DiskDataStartLBA :)
SldLoadRootDirectory:
    pusha
    mov ax, ROOT_DIRECTORY_SEGMENT ;root dir to 0x8000
    mov es, ax  
    ;calculate size of root directory
    mov ax, [RootDirEntryCount]

    mov bx, 32 ;32 bytes per entry
    mul bx
 
    xor dx, dx
    mov cx, [BytesPerSector]
    div cx
    mov [DiskDataStartLBA], ax 
    mov cx, ax
    ;calculate start of root directory
    mov ax, WORD [SectorsPerFAT]
    mov bl, BYTE [FATCount]
    mul bl
    
    add ax, [ReservedSectors]
    mov dl, [BootDriveNum]
    xor bx, bx
    add [DiskDataStartLBA], ax 
    call SldLoadSectors
    popa
    ret

SldLoadFAT:
    pusha
    push es
    xor bx, bx
    mov ax, FAT_SEGMENT
    mov es, ax
    mov ax, WORD [ReservedSectors]
    mov cx, WORD [SectorsPerFAT]
    mov dl, BYTE [BootDriveNum]
    xor bx, bx
    call SldLoadSectors
    pop es
    popa
    ret

;IN:
;DS:SI = Filename pointer
;ES:BX = Buffer
;DL = Drive
;OUT:
;CF = Set if failed
SldLoadFile:
    pusha
    ;find it in the root directory
    push es
    mov ax, ROOT_DIRECTORY_SEGMENT
    mov es, ax
    xor di, di
    xor bx, bx
    mov cx, WORD [RootDirEntryCount]
    .FindFile:
    push cx
    mov cx, 11
    push di
    push si
    rep cmpsb
    pop si
    pop di
    pop cx
    ;cmp di, 0x20
    je .FileFound
    add di, 32
    loop .FindFile

    pop es
    popa
    stc
    ret
    .FileFound:
    mov ax, WORD [es:di + 26]
    pop es    
    xor cx, cx
    movzx cx, BYTE [SectorsPerCluster]
    .LoadFileL:
    call SldLoadCluster
    mov cx, ax
    mov di, ax
    shr di, 1
    add di, cx
    push es
    mov cx, FAT_SEGMENT
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
        add bx, [BytesPerCluster]
        mov ax, dx
        cmp dx, 0x0FF0
        jb .LoadFileL
    popa
    ret

SldHalt:
    mov si, haltmsg
    call SldPrint16
    jmp near $
BPBJMP db 0,0,0   
;variables
%include 'bootloader/stage1/bpb.asm'
DiskDataStartLBA dw 0
BytesPerCluster dw 0
CHS_cylinders db 0
CHS_heads db 0
CHS_sectors db 0
;strings
fn_NOOLKRNL db "NOOLKRNLSYS"

shineon db "Remember when you were young, you shone like the sun. Shine on you crazy diamond", 0
prepkrnl db 0xA,0xD,0
failedtoload db "Error: Failed to load ",0
haltmsg db "Halting system...", 0
;other data
__GDTDATA:
;null descriptor
NullDescriptor:  dd 0
                 dd 0
;code descritpor
CodeDescriptor:dw 0xFFFF    ;limit low
               dw 0         ;base low
               db 0         ;base middle
               db 10011010b ;access
               db 11001111b ;granularity
               db 0         ;base high
;data descriptor
DataDescriptor:dw 0xFFFF    ;limit low
               dw 0         ;base low
               db 0         ;base middle
               db 10010010b ;access
               db 11001111b ;granularity
               db 0         ;base high
__GDTDATAEND:
__GDTPTR:
dw __GDTDATAEND - __GDTDATA - 1
dd __GDTDATA

BITS 32
Sld32Entry:
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov esp, 0xA0000
    xor eax, eax
    ;set A20
    mov al,0xD0 ;Read output port
    out 0x64, al
    call SldWaitFor8043
    
    in al,0x60 ;Get buffer data
    push eax
    call SldWaitFor8043

    mov al, 0xD1
    out 0x64, al
    call SldWaitFor8043

    pop eax
    or al, 2
    out 0x60, al
    ;test
    xor ax, ax
    a:
    call Sld32ClearScreen
    inc ah
    jnz a
    xor ah, ah
    call Sld32ClearScreen

    mov esi, Gap
    call Sld32Print
    mov ah, 70h
    mov esi, WelcomeStr
    call Sld32Print

    jmp 0x80000
    ;halt!
    cli
    hlt

%include 'bootloader/soareldr/pmode-video.asm'

SldWaitFor8043:
    pusha
    in al,0x64
    test al,2
    jnz SldWaitFor8043
    popa
    ret

Gap db "                  ",0
WelcomeStr db 178,178,178,177,177,177,176,176,176,"NoolOS-SOARELDR Boot Menu",176,176,176,177,177,177,178,178,178,0xA,0xD,0
PreparingToLoadKernel db "SOARELDR is preparing to load kernel",0xA, 0xD, 0

;KernelFilename db "NOOLKRNLSYS"