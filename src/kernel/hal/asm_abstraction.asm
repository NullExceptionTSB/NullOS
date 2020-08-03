BITS 32
section .text
    global HalaSendInterrupt
    HalaSendInterrupt:
        push ebp
        mov ebp, esp
        push eax
        mov al, BYTE [ebp+8]
        mov BYTE [intfunc+1], al
        pop eax
        intfunc:
        int 0xFF
        leave
        ret

    global HalaHalt
    HalaHalt:
        cli
        hlt
        jmp $

    global HalaSetIntFlag
    HalaSetIntFlag:
        sti
        ret

    global HalaClearIntFlag
    HalaClearIntFlag:
        cli
        ret

    global HalaLoadGDT
    HalaLoadGDT:
        push ebp   
        mov ebp, esp
        push ebx
        mov ebx, DWORD [ebp+8]
        lgdt [ebx]
        pop ebx
        leave
        ret

    global HalaLoadIDT
    HalaLoadIDT:
        push ebp   
        mov ebp, esp
        push ebx
        mov ebx, DWORD [ebp+8]
        lidt [ebx]
        pop ebx
        leave
        ret
;mom help im scared
    global HalaOutputPortByte
    HalaOutputPortByte:
        push ebp
        mov ebp, esp
        pusha
        mov dx, WORD [ebp+12]
        mov al, BYTE [ebp+8]
        out dx, al
        popa
        leave
        ret

    global HalaOutputPortWord
    HalaOutputPortWord:
        push ebp
        mov ebp, esp
        pusha
        mov dx, WORD [ebp+12]
        mov ax, WORD [ebp+8]
        out dx, ax
        popa
        leave
        ret

    global HalaOutputPortDword
    HalaOutputPortDword:
        push ebp
        mov ebp, esp
        pusha
        mov dx, WORD [ebp+12]
        mov eax, DWORD [ebp+8]
        out dx, eax
        popa
        leave
        ret

    global HalaInputPortByte
    HalaInputPortByte:
        push ebp
        mov ebp, esp
        xor eax, eax
        push dx
        mov dx, WORD [ebp+8]
        in al, dx
        pop dx
        leave
        ret

    global HalaInputPortWord
    HalaInputPortWord:
        push ebp
        mov ebp, esp
        xor eax, eax
        push dx
        mov dx, WORD [ebp+8]
        in ax, dx
        pop dx
        leave
        ret

    global HalaInputPortDword
    HalaInputPortDword:
        push ebp
        mov ebp, esp
        xor eax, eax
        push dx
        mov dx, WORD [ebp+8]
        in eax, dx
        pop dx
        leave
        ret
