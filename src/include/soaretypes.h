#ifndef _SOARETYPES_H
#define _SOARETYPES_H
#include <stdint.h>
typedef uint8_t     byte;
typedef uint16_t    word;
typedef uint32_t    dword;

/*0 = success, nonzero = failure, see error codes in krnlerrors.h under _STATUSERROR enum or documentation
exists as a simpler error-checking type then statuserror where you don't care what the error is
*/
typedef dword       status;
typedef int         boolean;

#define TRUE        1
#define FALSE       0
#define NULL        0


#endif
