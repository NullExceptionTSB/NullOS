#include <hal.h>
#include <soaretypes.h>
#include <soarekrnl.h>
#include <krnlerrors.h>

void HalhUnhandledInterrupt() {
    NklKernelPanic(0, 0, 0, 0, KERNELPANIC_UNHANDLED_INTERRUPT);
    //for (;;); //if for some reason NklKernelPanic doesn't halt the CPU
}