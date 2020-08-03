#ifndef _SOARE_HAL_H
#define _SOARE_HAL_H
#include <soaretypes.h>
#include <descriptors.h>
//kernel currently monolithic but will be converted to a hybrid kernel later
extern status HalInit();
extern status HalShutdown();
extern status HalInstallInterruptHandler(dword interruptNumber, idtflags idtFlags, word selector, interrupt_handler_function handler);
extern gdt_descriptor HalGenerateGDTDesc(dword baseAddress, dword segmentLimit, gdtflags gdtFlags);
extern idt_descriptor HalGenerateIDTDesc(dword baseAddress, word selector, idtflags idtFlags);
extern status HalAddGDTDesc(dword index, gdt_descriptor descriptor);
extern status HalAddIDTDesc(dword index, idt_descriptor descriptor);
extern void HalLoadGDT();
extern void HalLoadIDT();
//assembly
extern void HalaSendInterrupt(byte interrupt);
extern void HalaHalt();
extern void HalaClearIntFlag();
extern void HalaSetIntFlag();
extern void HalaLoadGDT(gdt_register* gdtRegPtr);
extern void HalaLoadIDT(idt_register* idtRegPtr);
extern void HalaOutputPortByte(byte value, word port);
extern void HalaOutputPortWord(word value, word port);
extern void HalaOutputPortDword(dword value, word port);
extern byte HalaInputPortByte(word port);
extern word HalaInputPortWord(word port);
extern dword HalaInputPortDword(word port);
#endif