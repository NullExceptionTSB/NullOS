#ifndef SOARE_GDT_H
#define SOARE_GDT_H

#pragma pack(push, 1)
#include "soaretypes.h"
struct _GDT_DESCRIPTOR {
    word limit;
    word baseLow;
    byte baseMid;
    word flags;
    byte baseHigh;
} gdt_descriptor;

#pragma pack(pop)

#endif