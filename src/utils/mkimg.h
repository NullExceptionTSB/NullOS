#pragma once
#include <stdint.h>
typedef enum _argflags {
    flag_input =        0x00000001,
    flag_force_fat12 =  0x00000002,
    flag_force_fat16 =  0x00000004,
    flag_output =       0x00000008,
    flag_verbose =      0x00000010,
    flag_noverif =      0x00000020,
    flag_partitioned =  0x00000040
}argflags;

typedef struct _chsA {
    unsigned int cylinders;
    unsigned int heads;
    unsigned int sectors;
    unsigned int sectorsPerTrack;
    unsigned int headsPerCylinder;
}chsA;

typedef struct _parsedargs {
    char* inputFile;
    char* mbrFile;
    char* outputFile;
    unsigned int fileSize;
    chsA chs; 
    argflags flags;
} parsedargs;

#pragma pack(push, 1)

typedef enum _bootflag {
    bootflag_unbootable =   0,
    bootflag_active =       0x80
} bootflag;

typedef struct _partition {
    unsigned char bootflag;
    unsigned char startHead;
    unsigned char startSector;
    unsigned char startCylinder;
    unsigned char systemID;
    unsigned char endHead;
    unsigned char endSector;
    unsigned char endCylinder;
    uint32_t startLBA;
    uint32_t partitionLen;
} partition;

typedef struct _partitionTable {
    uint32_t diskID;
    uint16_t reserved;
} partitionTable;