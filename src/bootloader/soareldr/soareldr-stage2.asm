%define ROOT_DIRECTORY_SEGMENT 0x800
%define FAT_SEGMENT 0x4000
%define FILESIZESTORAGE_SEGMENT 0x9F00

org 0x500
bits 16

SldEntry:
mov si, prepkrnl
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

;NULLKRNL.SYS -> 0x80000
mov ax, 0x8000
mov es, ax
mov si, fn_NULLKRNL
call SldPrint_LoadingFile
call SldLoadFile
jc SldPrint_FileLoadFailed
clc
;HAL.SYS -> 0x60000
mov ax, 0x6000
mov es, ax
mov si, fn_HAL
call SldPrint_LoadingFile
call SldLoadFile
jc SldPrint_FileLoadFailed
clc
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

SldPrint_LoadingFile:
    push si
    mov si, loadingfile
    call SldPrint16
    pop si
    call SldPrintFilename
    ret

SldPrint_FileLoadFailed:
    push si
    mov si, failedtoload
    call SldPrint16
    pop si
    call SldPrintFilename
    jmp SldHalt

SldPrintFilename:
    pusha
    push si
    add si, 7
    mov cx, 8
    .RemovePadding:
    mov al, [si]
    cmp al, 0x20
    jne .PostRemovePadding
    dec si
    loop .RemovePadding
    .PostRemovePadding:
    pop si
    push cx
    mov ah, 0Eh
    .PrintFilename:
    mov al, BYTE [si]
    int 10h
    inc si
    loop .PrintFilename
    jc .PostExtension
    pop cx
    sub si, cx
    add si, 8
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
    clc
    popa
    ret

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
;if you're having trouble loading clusters, chances are, this is why
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
    push es
    push si
    mov eax, DWORD [es:di + 28]
    mov cx, FILESIZESTORAGE_SEGMENT
    mov es, cx
    mov si, [FileSizeListIndex]
    shl si, 2 ; * 4 bytes
    mov DWORD [es:si], eax
    mov si, WORD [FileSizeListIndex]
    inc si
    mov WORD [FileSizeListIndex], si
    pop si
    pop es
    xor eax, eax
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
FileSizeListIndex dw 0
CHS_cylinders db 0
CHS_heads db 0
CHS_sectors db 0
;filenames
fn_NULLKRNL db "NULLKRNLSYE"
fn_HAL      db "HAL     SYS"
;strings
prepkrnl db 0xA,0xD,0
failedtoload db "Error: Failed to load ",0
loadingfile db "Loading file ",0
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

%define DST_KERNEL_ADDRESS  0x80000
%define KERNEL_IMAGE_BASE   0x100000
%define DST_HAL_ADDRESS     0x1000000
Sld32Entry:
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov esp, 0x9F0000

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
    ;mask PICs
    ;mov al, 0xFF
    ;out 0x21, al
    ;out 0xa1, al
    
    ;move loaded files to their desired location
    ;mov esi, FILESIZESTORAGE_SEGMENT
    ;shl esi, 4
    ;mov ecx, DWORD [es:esi]
    ;push esi
    ;mov esi, 0x80000 ;NULLKRNL.SYS @ 0x80000
    ;mov edi, DST_KERNEL_ADDRESS ;NULLKRNL.SYS @ 0x80000 -> 0x100000
    ;call CopyData

    ;pop esi
    ;add esi, 4
    ;push esi
    ;mov ecx, DWORD [es:esi]
    ;mov esi, 0x60000 ;HAL.SYS @ 0x60000
    ;mov edi, DST_HAL_ADDRESS ;HAL.SYS @ 0x60000 -> 0x1000000
    ;call CopyData

    ;verify kernel image and push entry point absolute address to stack
    mov esi, init_krnl
    call Sld32Print
    
    mov bx, WORD [DST_KERNEL_ADDRESS]
    cmp bx, "MZ"
    jne ErrorKernelCorrupt
    inc BYTE [kcorruptval]
    mov ebx, DWORD [DST_KERNEL_ADDRESS+60]
    add ebx, DST_KERNEL_ADDRESS
    mov eax, DWORD [ebx]
    cmp eax, 0x00004550
    jne ErrorKernelCorrupt
    inc BYTE [kcorruptval]
    add ebx, 4
    mov ax, WORD [ebx]
    cmp ax, 0x014C
    jne ErrorKernelCorrupt
    mov edx, ebx ;set EDX to the base of the section table
    add edx, 0xF4 ;section table base = NT header base + NT header size (0xF8) and there's 4 added for some reason  
    movzx ecx, WORD [ebx + 2] 
    add ebx, 20 ;set EBX to base of optional header
    inc BYTE [kcorruptval]
    mov ax, WORD [ebx]
    cmp ax, 0x10b
    jne ErrorKernelCorrupt
    inc BYTE [kcorruptval]
    mov eax, DWORD [ebx + 16] ;move entry point address offet to EAX
    jz ErrorKernelCorrupt
    add eax, KERNEL_IMAGE_BASE ;offset from the image base,
    push eax ;push it to the stack
    xor eax, eax
    mov esi, i_ValidKImage
    call Sld32Print
    ;find base of section table
    ;address of section table = address of optional header + size of optional header
    mov ebx, edx
    ;set ECX to the ammount of sections
    SectionLoadLoop:
        push ecx
        mov edi, [ebx + 12]
        mov ecx, [ebx + 16]
        mov esi, [ebx + 20]
        add edi, KERNEL_IMAGE_BASE
        add esi, DST_KERNEL_ADDRESS
                mov edx, DWORD [ebx]
        rep movsb
        pop ecx
        add ebx, 40
        loop SectionLoadLoop
    ;copy sections to their correct address, normally this is done via virtual memory
    xor ah, ah
    call Sld32ClearScreen
    ;print boot menu
    mov esi, Gap
    call Sld32Print
    mov ah, 70h
    mov esi, WelcomeStr
    call Sld32Print
    ;/===============================\
    ;|TODO: add functioning boot menu|
    ;\===============================/  
    xor ah, ah
    call Sld32ClearScreen
    ;execute kernel image
    pop ebx
    push ebp
    mov ebp, esp
    call ebx
    cli
    ;the kernel image returned! halt!
    mov esi, e_KernelReturn
    call Sld32Print
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

CopyData:
pusha
    .DataCopyLoop:
    mov dl, BYTE [es:esi]
    mov BYTE [es:edi], dl
    inc esi
    inc edi
    loop .DataCopyLoop
    popa
    ret

ErrorKernelCorrupt:
    xor eax, eax
    movzx edx, BYTE [kcorruptval]
    cmp edx, 1
    je .NotPESig
    cmp edx, 2
    je .InvalidArch
    cmp edx, 3
    je .InvalidOHSig
    cmp edx, 4
    je .NoEntry
    jne .Other
    .NotMZSig:
    mov esi, e_MzNotFound
    jmp short .PrintAndHalt
    .NotPESig:
    mov esi, e_PeNotFound
    jmp short .PrintAndHalt
    .InvalidArch:
    mov esi, e_KernelInvalidArch
    jmp short .PrintAndHalt
    .InvalidOHSig:
    mov esi, e_InvalidOHSig
    jmp short .PrintAndHalt
    .NoEntry:
    mov esi, e_NoEntry
    jmp short .PrintAndHalt
    .Other:
    mov esi, e_Other
    .PrintAndHalt:
    call Sld32Print
    Sld32Halt:
    cli
    hlt
    jmp Sld32Halt

kcorruptval db 0
init_krnl db "Parsing NullKrnl PE headers",0xD, 0xA,0
Gap db "                  ",0
WelcomeStr db 178,178,178,177,177,177,176,176,176,"NoolOS-SOARELDR Boot Menu",176,176,176,177,177,177,178,178,178,0xA,0xD,0
PreparingToLoadKernel db "SOARELDR is preparing to load kernel",0xA, 0xD, 0
e_MzNotFound db "MZ signature in DOS stub not found, kernel image corrupt, halting",0
e_PeNotFound db "PE signature not found, kernel image corrupt, halting",0
e_KernelInvalidArch db "Kernel architecture other then x86-32, kernel image invalid or corrupt, halting",0
e_InvalidOHSig db "Unexpected optional header signature, kernel image invalid or corrupt, halting",0
e_NoEntry db "No entry point specified, kernel image invalid or corrupt, halting", 0
e_Other db "Unknown error while verifying kernel image, halted", 0
e_KernelReturn db "Kernel image entry point returned, halted", 0
i_ValidKImage db "Kernel image valid", 0