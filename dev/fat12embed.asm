bits 16

;Copied from DankOS to Unreal OS to NoolOS
driverError db "driver error",0



PrintD: 
    pusha
    .MPrintD:
    lodsb      ;Load SI into AL
    or         al, al ;Get current character
    jz         .PrintDoneD ;Is it null ? If yes, jump to PrintDone, since it's a null terminated string.
    mov        bl, 09h ;Output the string
    mov        ah, 0eh ;Get contents of AL
    int        10h ;Interrupt call
	jc         FatalError ;Something somehow somewhere fucked up. Panic.
    jmp        .MPrintD ;Loop back to print
			
    .PrintDoneD:
	popa
    ret ;Exit this function

handleError:
    mov si, driverError
    call PrintD
	jmp getErrorStatus
	cli
	hlt
	

;Error detected here

;=============================;
;NEED TO SET BUFFER BEFORE USE
read_sector:
    pusha ;Save all registers
	
    xor dx, dx ;dx = 0
    div word [bpbSectorsPerTrack] ; al = al/bpbSectorsPerTrack
    inc dl ;dl +1 which means dx = 0001d
    mov byte [.absolute_sector], dl ;.absolute_sector = dl
    xor dx, dx ;dx = 0
    div word [bpbHeadsPerCylinder] ; al = al/bpbHeadsPerCylinder
    mov byte [.absolute_head], dl ; .absolute_head = dl
    mov byte [.absolute_track], al ; .absolute_track = al

    ;pop dx ;OwO whats this ?

    mov ah, 2h ;Function 2h, Read sectors
    mov al, 1h ;Sectors to read (1)
    mov ch, byte [.absolute_track] ;Set tracks
    mov cl, byte [.absolute_sector] ;Set sector to read
    mov dh, byte [.absolute_head] ;Set heads
    xor dl, dl ;dl = 0
	
	
    clc
    int 0x13
    jc handleError ;Captured here
.done:
    popa
    retn
	
	
;End
.absolute_sector db 00h
.absolute_head	db 00h
.absolute_track	db 00h
read_sectors:
    push ax
    push bx
    push cx

.loop:
    call read_sector
    jc .done

    inc ax
    add bx, 0x200

    loop .loop

.done:
    pop cx
    pop bx
    pop ax
    retn
	
getErrorStatus:
   mov ah, 01h
   mov dl, 00h
   int 13h