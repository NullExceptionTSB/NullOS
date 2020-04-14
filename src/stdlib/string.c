#include <size_t.h>

void* memcpy(void* dest, const void* src, size_t len) {
    char* d = (char*)dest;
    char* s = (char*)src;
    while (len--) *(char*)d++ = *(char*)s++;
    return dest;
}

void* memset(void* dest, int val, size_t len) {
    unsigned char* d = dest;
    while (len--) *d++ = val;
    return dest;
}

int strcmp(const char* p1, const char* p2) {
    const char* a = p1;
    const char* b = p2;
    char c1, c2;

    do {
        c1 = *a++;
        c2 = *b++;
        if (!c1) break;
    } while (c1 == c2);
    return c1 - c2;
}

size_t strlen(char* str) {
    char* p = str;
    size_t s = 0;
    while (*p++) s++;
    return s;
}
