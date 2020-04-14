%DEFINE COLUMNS 80
%DEFINE LINES 25
%DEFINE VIDEOMEMORY 0x000B8000
%DEFINE DEFAULT_ATTRIB 07h

;AL=character
;AH=attribs
;CX=X
;DX=Y
Sld32Putchar:
    pusha
    push ax
    ;(y*width)
    mov ax, dx
    mov bx, COLUMNS
    mul bx
    mov dx, ax
    pop ax
    ;+x
    add cx, dx
    shl cx, 1
    mov edi, VIDEOMEMORY
    add edi, ecx
    mov WORD [edi], ax
    popa
    ret

;CX=X
;DX=Y
Sld32SetCursorPos:
    pusha
    ;first calculate the x+(y*W) offset
    mov ax, dx
    xor dx, dx
    mov bx, COLUMNS
    mul bx
    xor dx, dx
    add cx, ax
    ;now it's in CX, conglarturation
    ;set up the CRT controller
    mov al, 0x0F ;select 0x0F into index register
    mov dx, 0x03D4
    out dx, al
    ;write low part
    mov al, cl
    mov dx, 0x03D5
    out dx, al
    ;set it up to write the high part
    mov al, 0x0E
    mov dx, 0x03D4
    out dx, al
    ;write high part
    mov al, ch
    mov dx, 0x03D5
    out dx, al
    popa
    ret

;AH=attribs
Sld32ClearScreen:
    pusha
    test ah, 0
    jnz .nonzero
    mov ah, DEFAULT_ATTRIB
    .nonzero:
    mov WORD [CursorPosX], 0
    mov WORD [CursorPosY], 0
    xor cx, cx
    xor dx, dx
    call Sld32SetCursorPos
    xor al, al
    mov edi, VIDEOMEMORY
    mov cx, 0x2000
    rep stosw
    popa
    ret

;AL=character
;AH=attribs
Sld32Printchar:
    pusha
    mov cx, [CursorPosX]
    mov dx, [CursorPosY]
    cmp al, 0xA
    je .NewLine
    cmp al, 0xD ;is it carrige return
    je .Carrige
    call Sld32Putchar
    ;is it a newline
 
    inc cx
    cmp cx, COLUMNS
    jne .PostCarrige
    mov cx, 0
    .NewLine:
    inc dx
    jmp .PostCarrige
    .Carrige:
    mov cx, 0
    .PostCarrige:
    mov [CursorPosX], cx
    mov [CursorPosY], dx
    call Sld32SetCursorPos
    popa
    ret

;ESI=String
;AH=Attributes
Sld32Print:
pusha
or ah, ah
jnz .PrintCycle
mov ah, DEFAULT_ATTRIB
    .PrintCycle:
    mov al, BYTE [esi]
    or al, al
    jz .PrintEnd
    call Sld32Printchar
    inc esi
    jmp .PrintCycle
    .PrintEnd:
    popa
    ret
CursorPosX DW 0
CursorPosY DW 6