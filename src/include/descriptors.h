#ifndef _DESCRIPTORS_H
#define _DESCRIPTORS_H

#define MAX_GLOBAL_DESCRIPTORS          8192
#define MAX_INTERRUPT_DESCRIPTORS       256
#pragma pack(push, 1)
#include <soaretypes.h>
typedef struct _GDT_DESCRIPTOR {
    word limit;
    word baseLow;
    byte baseMid;
    word flags;
    byte baseHigh;
} gdt_descriptor;

typedef enum _GDTFLAGS {
    gdt_accessBit =                 0x00000001,
    gdt_isDescriptorWriteable =     0x00000002,
    gdt_expandDown =                0x00000004,
    gdt_isConforming =              0x00000004,
    gdt_isExecutable =              0x00000008,
    gdt_isCodeOrDataDescriptor =    0x00000010,
    gdt_ring0 =                     0x00000000,
    gdt_ring1 =                     0x00000020,
    gdt_ring2 =                     0x00000040,
    gdt_ring3 =                     0x00000060,
    gdt_segmentIsInMemory =         0x00000080,
    gdt_reservedOSUse =             0x00000800,
    gdt_segmentIs32Bit =            0x00004000,
    gdt_granularity =               0x00008000
} gdtflags;

typedef struct _IDT_DESCRIPTOR {
    word baseLow;
    word selector;
    byte reserved;
    byte flags;
    word baseHigh;
} idt_descriptor;

typedef enum _IDTFLAGS {
    idt_type_32bitTaskGate =             0x00000005,
    idt_type_16bitInterruptGate =        0x00000006,
    idt_type_16bitTrapGate =             0x00000007,
    idt_type_32bitInterruptGate =        0x0000000E,
    idt_type_32bitTrapGate =             0x0000000F,
    idt_storage_segment =                0x00000010,
    idt_ring0 =                          0x00000000,
    idt_ring1 =                          0x00000040,
    idt_ring2 =                          0x00000020,
    idt_ring3 =                          0x00000060,
    idt_present =                        0x00000080,
} idtflags;

typedef struct _DESCRIPTOR_TABLE_REGISTER {
    word cb;
    dword tableBase;
    word reserved
}gdt_register, idt_register;

typedef void (*interrupt_handler_function)(void);

#pragma pack(pop)

#endif