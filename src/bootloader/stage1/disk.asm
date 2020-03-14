%ifndef SOARE_STAGE1_DISK
%define SOARE_STAGE1_DISK
CHS_cylinders db 0
CHS_heads db 0
CHS_sectors db 0

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
LoadSector:
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

actually_read dw 0
LoadSectors:
pusha
mov WORD [actually_read], cx
    .readLoop:
    clc
    call LoadSector
    inc ax
    add bx, 512
    jc .failed
    loop .readLoop
    jmp .done
    .failed:
    sub [actually_read], cx
    .done:
    popa
    mov cx, [actually_read]
    ret

;AX = cluster
;ES:BX = buffer
LoadCluster:
pusha
sub ax, 2
;now, nobody bothered to tell me this but the fucking shit's base address is after the root directory. on one hand
;i'm stupid for not realising it myself, on the other, fuck you.
add ax, [DiskDataStartLBA]
mov dl, [BootDriveNum]
movzx cx, BYTE [SectorsPerCluster] 
call LoadSectors
popa
ret
%endif 