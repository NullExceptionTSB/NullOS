%ifndef _SOARE_DISK_ASM
%define _SOARE_DISK_ASM
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

LoadSectors:
pusha
    .readLoop:
    clc
    call LoadSector
    inc ax
    add bx, 512
    jc .done
    loop .readLoop
    jmp .done
    .done:
    popa
    ret

;AX = cluster
;ES:BX = buffer
LoadCluster:
pusha
sub ax, 2
add ax, [DiskDataStartLBA]
mov dl, [BootDriveNum]
movzx cx, BYTE [SectorsPerCluster] 
call LoadSectors
popa
ret
%endif