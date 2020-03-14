;This will be a COM program but is currently not segmented
;this won't be a com program and will use a custom format
;actually this will just be a flat binary forever to make things easier

org 0x500
bits 16

SldEntry:
mov si, prepkrnl
call SldPrint16
mov si, shineon
call SldPrint16

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



SldPrint16:
    lodsb
    or al, al
    jz .print16End
    mov ah, 0Eh
    int 10h
    jmp SldPrint16
        .print16End:
        ret



SldHalt:
    mov si, haltmsg
    call SldPrint16
    jmp near $

;variables

;strings
shineon db "Remember when you were young, you shone like the sun. Shine on you crazy diamond",0xA, 0xD, 0
prepkrnl db 0xA,0xD,"SOARELDR is preparing to load kernel",0xA, 0xD, 0
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
    ;print test char
    
    mov esi, TestStr
    call Sld32Print
    ;halt!
    cli
    hlt

%include "soareldr/pmode-video.asm"

SldWaitFor8043:
    pusha
    in al,0x64
    test al,2
    jnz SldWaitFor8043
    popa
    ret
    
TestStr db "Testing 32-bit video",0xA,0xD,"If this printed correctly, video works :)",0