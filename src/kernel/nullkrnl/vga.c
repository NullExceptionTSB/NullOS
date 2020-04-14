#include <soarevga.h>
#include <size_t.h>
char defaultAttributes = DEFAULT_ATTRIB;
dword curX = 0, curY = 0;
word* screendata = (word*)0x000B8000;
void VgaPutCharacter(char character, char character_attributes, dword x, dword y) {
    word chardata = (!character_attributes ? defaultAttributes : character_attributes) << 8 | character;
    screendata[y*COLUMNS+x] = chardata;
}

void VgaSetCursorPos(dword x, dword y) {
    curX = x;
    curY = y;
    word curindex = y*COLUMNS+x;
    #ifdef _WIN32
    __asm {
        mov cx, curindex
        mov al, 0x0F
        mov dx, 0x03D4
        out dx, al
        mov al, cl
        mov dx, 0x03D5
        out dx, al
        mov al, 0x0E
        mov dx, 0x03D4
        out dx, al
        mov al, ch
        mov dx, 0x03D5
        out dx, al
    }
    #else
    asm (
        "mov al, 0x0F\n\t"
        "mov dx, 0x03D4\n\t"
        "out dx, al\n\t"
        "mov al, cl\n\t"
        "mov dx, 0x03D5\n\t"
        "out dx, al\n\t"
        "mov al, 0x0E\n\t"
        "mov dx, 0x03D4\n\t"
        "out dx, al\n\t"
        "mov al, ch\n\t"
        "mov dx, 0x03D5\n\t"
        "out dx, al\n\t"
        :
        :"c" (curindex)
        :
    );
    #endif
}

void VgaClearScreen(char character_attributes) {
    if (character_attributes != defaultAttributes && character_attributes != 0) 
        defaultAttributes = character_attributes;

    word wipechar = (character_attributes == 0 ? defaultAttributes : character_attributes) << 8;
    for (dword i = 0; i < COLUMNS * LINES; i++)
        screendata[i] = wipechar;
}

void VgaPrintChar(char character, char character_attributes) {
    switch (character) {
        case 0xA:
            curX = 0;
            break;
        case 0xD:
            curY++;
            break;
        default:
            VgaPutCharacter(character, character_attributes, curX, curY);
            curX++;
            if (curX == COLUMNS) {
                curX = 0;
                curY++;
            }
            break;
    }
    VgaSetCursorPos(curX, curY);
}

void VgaPrintString(char* string, char character_attributes) {
    for (dword i = 0; string[i] != '\0'; i++) {
        VgaPrintChar(string[i], character_attributes);
        if (i > COLUMNS * LINES) break;
    }
}

void VgaSetGlobalAttributes(char character_attributes) {
    for (dword i = 1; i < COLUMNS * LINES * 2; i+=2)
        ((char*)screendata)[i] = character_attributes;
}

void VgaPrintIntegerDec(int integer, boolean isSigned) {
    int32_t num = integer;
    uint32_t unum = integer;
    boolean isNegative = FALSE;
    size_t len = 0;
    dword startIndex = (curX + curY * COLUMNS);
    word intermediate;
    //if the sign bit is set and the number is signed, get the absolute value of the integer and set a boolean value
    if (num & 0x80000000 && isSigned) {
        num = 0 - num;
        isNegative = TRUE;
    }

    if (isSigned){
        while (num) {
            VgaPrintChar('0' + (num % 10), 0);
            num /= 10;
            len++;
        }
    }
    else {
        while (unum) {
            VgaPrintChar('0' + (unum % 10), 0);
            unum /= 10;
            len++;
        }
    }

    if (isNegative) {
        VgaPrintChar('-', 0);
        len++;
    }
    
    for (dword i = 0, j = len; i < j; i++, j--){
        intermediate = screendata[i+startIndex];
        screendata[i+startIndex] = screendata[j+startIndex-1];
        screendata[j+startIndex-1] = intermediate;
    }
}

void VgaPrintIntegerHex(int integer) {
    uint32_t num = integer;
    uint32_t digit = 0;

    size_t len = 8;
    dword startIndex = (curX + curY * COLUMNS);
    word intermediate;
    //if the sign bit is set and the number is signed, get the absolute value of the integer and set a boolean value


    for (dword i = 0; i < len; i++) {
        digit = num % 16;
        if (digit < 10) {
            VgaPrintChar('0' + digit, 0);
        }
        else {
            VgaPrintChar('A'+ (digit - 10), 0);
        } 
        num /= 16;
    }
    
    VgaPrintString("x0", 0);
    len += 2;

    for (dword i = 0, j = len; i < j; i++, j--) {
        intermediate = screendata[i+startIndex];
        screendata[i+startIndex] = screendata[j+startIndex-1];
        screendata[j+startIndex-1] = intermediate;
    }
}