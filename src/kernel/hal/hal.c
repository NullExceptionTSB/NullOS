#include <hal.h>
#include <descriptors.h>
#include <soaretypes.h>
#include <string.h>
#include <soarevga.h>
#include <halhandlers.h>
#include <krnlerrors.h>

gdt_descriptor GDTTable[MAX_GLOBAL_DESCRIPTORS];
idt_descriptor IDTTable[MAX_INTERRUPT_DESCRIPTORS];

gdt_register GDTR;
idt_register IDTR;
status HalInit() {  
    memset(GDTTable, 0, sizeof(gdt_descriptor) * MAX_GLOBAL_DESCRIPTORS);
    memset(IDTTable, 0, sizeof(idt_descriptor) * MAX_INTERRUPT_DESCRIPTORS);

    GDTR.tableBase = (dword)GDTTable;
    GDTR.cb = (MAX_GLOBAL_DESCRIPTORS * sizeof(gdt_descriptor)) - 1;
    IDTR.tableBase = (dword)IDTTable;
    IDTR.cb = (MAX_INTERRUPT_DESCRIPTORS * sizeof(idt_descriptor)) - 1;
    VgaPrintString("GDT Base: ", 0);
    VgaPrintIntegerHex((dword)GDTTable);
    VgaPrintString("\r\nIDT Base: ", 0);
    VgaPrintIntegerHex((dword)IDTTable);

    //null descriptor
    gdt_descriptor GDTDesc;
    memset(&GDTDesc, 0, sizeof(gdt_descriptor));
    HalAddGDTDesc(0, GDTDesc);
    //code descriptor
    GDTDesc = HalGenerateGDTDesc(0, 0xFFFFFFFF, gdt_isDescriptorWriteable | gdt_isExecutable | gdt_isCodeOrDataDescriptor | gdt_segmentIsInMemory | 
                        gdt_granularity | gdt_segmentIs32Bit | gdt_ring0);
    HalAddGDTDesc(1, GDTDesc);
    //data descriptor
    GDTDesc = HalGenerateGDTDesc(0, 0xFFFFFFFF, gdt_isDescriptorWriteable | gdt_isCodeOrDataDescriptor | gdt_segmentIsInMemory | gdt_segmentIs32Bit |
                        gdt_granularity | gdt_ring0);
    HalAddGDTDesc(2, GDTDesc);
    //load GDT
    HalaLoadGDT(&GDTR);
    
    //init IDT
    for (int i = 0; i < MAX_INTERRUPT_DESCRIPTORS; i++) {
        status ret = HalInstallInterruptHandler(i, idt_present | idt_ring0 | idt_type_32bitInterruptGate, 0x8, HalhUnhandledInterrupt);
        if (ret) return ret;
    }
    //load idt
    HalaLoadIDT(&IDTR);
    HalSetPitMask(0xFF, 0xFF);
    HalaSetIntFlag();
    //HalaSendInterrupt(0xDE);
    for (;;);
    return 0;
}

gdt_descriptor HalGenerateGDTDesc(dword baseAddress, dword segmentLimit, gdtflags gdtFlags) {
    gdt_descriptor returnedDescriptor;
    memset(&returnedDescriptor, 0, sizeof(gdt_descriptor));
    /*
    word descflags = gdtFlags;
    descflags |= (segmentLimit & 0x000F0000) << 8;
    */
    returnedDescriptor.flags = gdtFlags;
    returnedDescriptor.limit = (word)segmentLimit;
    returnedDescriptor.baseLow = (word)baseAddress;
    returnedDescriptor.baseMid = (byte)((baseAddress >> 16));
    returnedDescriptor.baseHigh = (byte)((baseAddress >> 24));
    return returnedDescriptor;
}

idt_descriptor HalGenerateIDTDesc(dword baseAddress, word selector, idtflags idtFlags) {
    idt_descriptor returnedDescriptor;
    returnedDescriptor.reserved = 0;
    returnedDescriptor.flags = idtFlags;
    returnedDescriptor.selector = selector;
    returnedDescriptor.baseLow = baseAddress & 0xFFFF;
    returnedDescriptor.baseHigh = (baseAddress >> 16) & 0xFFFF;
    return returnedDescriptor;
}

status HalAddGDTDesc(dword index, gdt_descriptor descriptor) {
    if (index >= MAX_GLOBAL_DESCRIPTORS)
        return STATUSERROR_NOT_ENOUGH_SPACE;
    GDTTable[index] = descriptor;
    return STATUSERROR_SUCCESS;
}

status HalAddIDTDesc(dword index, idt_descriptor descriptor) { 
    if (index >= MAX_INTERRUPT_DESCRIPTORS)
        return STATUSERROR_NOT_ENOUGH_SPACE;
    IDTTable[index] = descriptor;
    return STATUSERROR_SUCCESS;
}

status HalInstallInterruptHandler(dword interruptNumber, idtflags idtFlags, word selector, interrupt_handler_function handler) {
    if (interruptNumber > MAX_INTERRUPT_DESCRIPTORS) 
        return STATUSERROR_NOT_ENOUGH_SPACE;

    if (!handler)
        return STATUSERROR_INVALID_PARAMETERS;

    idt_descriptor desc = HalGenerateIDTDesc((dword)handler, selector, idtFlags);
    return HalAddIDTDesc(interruptNumber, desc);
    
}

void HalSetPitMask(byte masterMask, byte slaveMask) {
    HalaOutputPortByte(masterMask, 0x21);
    HalaOutputPortByte(slaveMask, 0xa1);
}

status HalShutdown() {
    return -1; //stub
}