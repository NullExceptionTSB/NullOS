#ifndef _STRING_H
#define _STRING_H

#include <size_t.h>

void* memcpy(void* dest, const void* src, size_t len);
void* memset(void* dest, int val, size_t len);
int strcmp(const char* p1, const char* p2);
size_t strlen(const char* str);

#endif
