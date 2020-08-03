#include <hal.h>
#include <soaretypes.h>
#include <soarevga.h>
#include <krnlerrors.h>

void NklKernelPanic(dword arg1, dword arg2, dword arg3, dword arg4, kernelpanic reason) {
    //INFO: the current reg dump is correct except for ESP, EBP and EIP which are meant to be printed in the state they were in
    //when NklKernelPanic was called
    dword esp_var;
    #ifdef _WIN32
        __asm {
            push eax
            mov esp_var, ebp
        }
    #else  
        asm("push eax");
        __asm__( "mov %0, ebp" : "=r" (esp_var) :: );
    #endif
    esp_var += 24;

    dword eax_var, ebx_var, ecx_var, edx_var, ebp_var, esi_var, edi_var, eip_var;
    eip_var = *(dword*)(((dword)(&arg1)) - 4) - 4; //first arg address (args are pushed last to first) - size of last arg (4 in this case)
                                                //this is because with CDECL, arguments are pushed right to left so the first arg is the last
                                                //to be pushed to the stack, and the return address is stored directly after the last arg on the stack
                                                //5 is subtracted because it's the size of the call instruction

    ebp_var = (*(dword*)(((dword)(&arg1)) - 8)); //simmilar logic to above, the first instruction after EIP is pushed (via call instruction)
                                                        //is push ebp (creating stack frame), so EBP is directly after the start address.

    esp_var += 0x10; //i have no fucking idea

        //put all registers into variables  
#ifdef _WIN32
    __asm {
        mov edi_var, edi
        mov esi_var, esi
        mov ebp_var, ebp
        mov ebx_var, ebx
        mov edx_var, edx
        mov ecx_var, ecx
        mov eax_var, eax
    }
#else
    asm("pop eax");
    __asm__ volatile ( "": "=a" (eax_var) : : );
    __asm__ volatile ( "": "=d" (edx_var) : : );
    __asm__ volatile ( "": "=b" (ebx_var) : : );
    __asm__ volatile ( "": "=c" (ecx_var) : : );
    __asm__ volatile ( "": "=D" (edi_var) : : );
    __asm__ volatile ( "": "=S" (esi_var) : : );
#endif
    
    //this isn't pretty at all, if anyone has any ideas on how to make this prettier, let me know. 
    //i currently haven't implemented printf, so that is obviously one way to do that
    VgaClearScreen(0);
    VgaSetCursorPos(0,1);
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
    VgaPrintString("Attributes: { ", 0);
    VgaPrintIntegerHex(arg1);
    VgaPrintString(", ", 0);
    VgaPrintIntegerHex(arg2);
    VgaPrintString(", ", 0);
    VgaPrintIntegerHex(arg3);
    VgaPrintString(", ", 0);
    VgaPrintIntegerHex(arg4);
    VgaPrintString(" }\n\rSystem halted", 0);
    HalaHalt();
}

void NklEntry() {
    VgaClearScreen(0x1F);
    VgaPrintString("Initializing HAL...\n\r\0", 0);
    //asm("hlt");
    statuserror HalStatus = HalInit();
    if (HalStatus)
        NklKernelPanic(HalStatus, 0, 0, 0, KERNELPANIC_HAL_FAILURE);
    NklKernelPanic(0,0,0,0, KERNELPANIC_REACHED_END_OF_KERNEL_CODE);
    HalaHalt();
}