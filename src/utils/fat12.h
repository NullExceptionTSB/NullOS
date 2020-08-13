#pragma once
#include <stdint.h>
#pragma pack(push, 1)
typedef unsigned char byte;
typedef struct _bios_parameter_block{
    byte jumpcode[3];
    char OEMlabel[8];
    uint16_t bytesPerSector;
    uint8_t sectorsPerCluster;
    uint16_t reservedSectors;
    uint8_t fatCount;
    uint16_t rootDirectoryEntries;
    uint16_t totalSectors;
    uint8_t mediaDescriptorByte;
    uint16_t sectorsPerFat;
    uint16_t sectorsPerTrack;
    uint16_t headCount;
    uint32_t hiddenSectors;
    uint32_t largeSectors;
    uint8_t bootDriveNumber;
    uint8_t reserved;
    uint8_t signature;
    uint32_t serialNumber;
    char label[11];
    char filesystem[8];
}bios_parameter_block;
#pragma pack(pop)
#pragma 