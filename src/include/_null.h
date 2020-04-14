#ifndef __NULL_H
#define __NULL_H
//pragma once if avalible
#if defined (_MSC_VER) & (MSC_VER >= 1020)
#pragma once
#endif

#ifdef NULL
#undef NULL
#endif

#ifdef __cplusplus
extern "C"
{
#define NULL 0
}
#else
#define NULL (void*)0
#endif

#endif
