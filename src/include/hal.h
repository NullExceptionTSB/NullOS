#ifndef _SOARE_HAL_H
#define _SOARE_HAL_H
#include "soaretypes.h"
//kernel currently monolithic but will be converted to a hybrid kernel later
extern status HalInit();
extern status HalShutdown();
#endif