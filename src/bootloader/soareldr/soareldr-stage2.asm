;This will be a COM program but is currently not segmented
;this won't be a com program and will use a custom format

org 0x100
bits 16

main:
mov si, prepkrnl
call print16
mov si, shineon
call print16

jmp halt

print16:
    lodsb
    or al, al
    jz .print16End
    mov ah, 0Eh
    int 10h
    jmp print16
        .print16End:
        ret

halt:
    mov si, haltmsg
    call print16
    jmp near $

shineon db "Remember when you were young, you shone like the sun. Shine on you crazy diamond",0xA, 0xD, 0

prepkrnl db 0xA,0xD,"SOARELDR is preparing to load kernel",0xA, 0xD, 0
haltmsg db "Halting system...", 0

