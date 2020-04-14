#ifndef _SOAREVGA_H
#define _SOAREVGA_H
#define COLUMNS 80
#define LINES 25
#define DEFAULT_ATTRIB 0x07
#include <soaretypes.h>
void VgaPutCharacter(char character, char character_attributes, dword x, dword y);
void VgaSetCursorPos(dword x, dword y);
void VgaClearScreen(char character_attributes);
void VgaPrintChar(char character, char character_attributes);
void VgaPrintString(char* string, char character_attributes);
void VgaSetGlobalAttributes(char character_attributes);
void VgaPrintIntegerDec(int integer, boolean isSigned);
void VgaPrintIntegerHex(int integer);
#endif