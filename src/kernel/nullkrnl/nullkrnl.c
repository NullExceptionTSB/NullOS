#include <hal.h>
#include <soaretypes.h>
#include <soarevga.h>

void NklHalt() {
#ifdef _WIN32
    __asm hlt
#else
    __asm__ ( "hlt" );
#endif
}

void NklKernelPanic(dword arg1, dword arg2, dword arg3, dword arg4, dword reason) {
    //INFO: the current regiter dump feature DOESN'T WORK CORRECTLY! 5/9 of the registers are INCORRECT! The ones that are correct are EAX, EBX, EDI and ESI

    dword eax_var, ebx_var, ecx_var, edx_var, esp_var, ebp_var, esi_var, edi_var, eip_var;

    //push all general purpous registers to stack
#ifdef _WIN32
    __asm pushad
#else
    __asm__ ( "pushad" );
#endif

    //put all registers into variables
#ifdef _WIN32
    __asm {
        pop edi_var
        pop esi_var
        pop ebp_var
        add esp, 4
        mov esp_var, esp
        pop ebx_var
        pop edx_var
        pop ecx_var
        pop eax_var
        pop eip_var
    }
#else
    __asm__ ( "pop %0" : "=r" (edi_var) : : );
    __asm__ ( "pop %0" : "=r" (esi_var) : : );
    __asm__ ( "pop %0" : "=r" (ebp_var) : : );
    __asm__ ( "add esp, 4\n\tmov %0, esp" : "=r" (esp_var) : : );
    __asm__ ( "pop %0" : "=r" (ebx_var) : : );
    __asm__ ( "pop %0" : "=r" (edx_var) : : );
    __asm__ ( "pop %0" : "=r" (ecx_var) : : );
    __asm__ ( "pop %0" : "=r" (eax_var) : : );
    __asm__ ( "add esp, 4\n\tpop %0" : "=r" (eip_var) : : );
#endif
    //this isn't pretty at all, if anyone has any ideas on how to make this prettier, let me know. 
    //i currently haven't implemented printf, so that is obviously one way to do that
    VgaClearScreen(0);
    VgaPrintString("Kernel Panic, error code ", 0);
    VgaPrintIntegerHex(reason);
    VgaPrintString("\n\rRegister dump:\n\rEAX: ", 0 );
    VgaPrintIntegerHex(eax_var);
    VgaPrintString(" EBX: ", 0);
    VgaPrintIntegerHex(ebx_var);
    VgaPrintString(" ECX: ", 0);
    VgaPrintIntegerHex(ecx_var);
    VgaPrintString(" EDX: ", 0);
    VgaPrintIntegerHex(edx_var);
    VgaPrintString("\n\rESP: ", 0);
    VgaPrintIntegerHex(esp_var);
    VgaPrintString(" EBP: ", 0);
    VgaPrintIntegerHex(ebp_var);
    VgaPrintString(" EIP: ", 0);
    VgaPrintIntegerHex(eip_var);
    VgaPrintString("\n\rESI: ", 0);
    VgaPrintIntegerHex(esi_var);
    VgaPrintString(" EDI: ", 0);
    VgaPrintIntegerHex(edi_var);
    VgaPrintString("\n\r", 0);
    for (dword i = 0; i > COLUMNS / 2; i++) VgaPrintChar('=',0);
    VgaPrintString("Attributes: { ", 0);
    VgaPrintIntegerHex(arg1);
    VgaPrintString(", ", 0);
    VgaPrintIntegerHex(arg2);
    VgaPrintString(", ", 0);
    VgaPrintIntegerHex(arg3);
    VgaPrintString(", ", 0);
    VgaPrintIntegerHex(arg4);
    VgaPrintString(" }\n\rSystem halted", 0);
    NklHalt();
}

void NklEntry() {
    VgaClearScreen(0x1F);
    VgaPrintString("Initializing HAL...\n\r\0", 0);
    HalInit();
    NklHalt();
}