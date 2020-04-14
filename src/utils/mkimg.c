#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#pragma pack(1)
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

typedef enum _argflags {
    flag_input =        0x00000001,
    flag_force_fat12 =  0x00000002,
    flag_force_fat16 =  0x00000004,
    flag_output =       0x00000008,
    flag_verbose =      0x00000010,
    flag_noverif =      0x00000020
}argflags;

typedef struct _parsedargs {
    char* inputFile;
    char* outputFile;
    argflags flags;
} parsedargs;

void fail(char* string) {
    puts(string);
    exit(1);
}

parsedargs parse_args(char* argv[], int argc) {
    parsedargs parsed_args;
    argflags flags = 0;
    if (argc > 1) {
        for (int argi = 1; argi < argc; argi++) {
            if (argv[argi][0] == '-') {
                int arglen = strlen(argv[argi]);
                if (arglen < 2) break;
                for (int i = 1; i < arglen; i++){
                    switch (argv[argi][i]) {
                        case 'h':
                            fail("-f: Force FAT12, cannot use with -F\n-F: Force FAT16, cannot use with -f\n-h: Show this message\n-i: Specifies the next argument is the bootsector [this arg is mandatory]\n-o: Specifies the next argument is the output [this arg is mandatory]\n-v: Verbose mode\n-c: Don't verify if bootsector is valid");
                            break;
                        case 'o':
                            flags |= flag_output;
                            parsed_args.outputFile = argv[argi+1];
                            break;
                        case 'i':
                            flags |= flag_input;
                            parsed_args.inputFile = argv[argi+1];
                            break;
                        case 'f':
                            flags |= flag_force_fat12;
                            break;
                        case 'F':
                            flags |= flag_force_fat16;
                            break;
                        case 'v':
                            flags |= flag_verbose;
                            break;
                        case 'c':
                            flags |= flag_noverif;
                            break;
                    }
                }
            }
        }
    }
    if (argc == 1) 
        fail("Usage: genfat12image (options: -fFhvc) -i [bootsector] -o [output]");
    if ((flags & flag_force_fat12) && (flags & flag_force_fat16)) 
        fail("F: Invalid combination of args");
    if (!(flags & flag_input))
        fail("F: Input file not specified");
    if (!(flags & flag_output))
        fail("F: Output file not specified");

    parsed_args.flags = flags;
    return parsed_args;
}

int main(int argc, char* argv[]) {
    parsedargs parsed_args = parse_args(argv, argc);
    puts("mkimg by NullException");

    unsigned int verbose = parsed_args.flags & flag_verbose;
    FILE* srcfile;
    FILE* dstfile;
    char* filename = parsed_args.inputFile;
    char* dest = parsed_args.outputFile;
    byte* buffer = malloc(512);
    bios_parameter_block* bpb = buffer;
    srcfile = fopen(filename, "r");
    byte* floppyimage;
    if (!srcfile) fail("F: Cannot open bootsector file");

    if (access(dest, F_OK) != -1)
        if (remove(dest) == -1) fail("F: Cannot delete existing floppy image");

    dstfile = fopen(dest, "w");
    if (!dstfile) 
        fail("F: Unable to create floppy image file");
    fread(buffer, 1, 512, srcfile);
    fclose(srcfile);

    if (!(parsed_args.flags & flag_noverif)) {
        if (verbose) printf("V: Verfying media descriptor byte, 0x%02X\n", bpb->mediaDescriptorByte);
        if (!(bpb->mediaDescriptorByte & 0xD0))
            fail("E: Media descriptor byte invalid");
        if (verbose) printf("V: Checking if bootsig is present and correct, bootsig: 0x%04X, expected 0xAA55\n", *((uint16_t*)((void*)buffer + 510)));
        if (*((uint16_t*)((void*)buffer + 510)) != 0xAA55)
            puts("W: Bootsig not present, image will not be bootable");
        if (bpb->signature == 0x28 && verbose) puts("V: Extended bootsig found, BPB 3.4");
        else if (bpb->signature == 0x29 && verbose) puts("V: Extended bootsig found, BPB 4.0");
        else if (bpb->signature == 0x80) puts("W: Extended bootsig specifies NTFS, this file system is NOT SUPPORTED!");
        else if (bpb->signature != 0x28 && bpb->signature != 0x29) puts("W: Invalid extended bootsig, this can mean that either you're using an old version of the BPB or that the bootsector is invalid or corrupted");
    }
    else puts("I: -c specified, skipping verification");

    size_t imgsize = bpb->totalSectors * bpb->bytesPerSector;
    double sizeInMegabytes = ((double)imgsize)/1000000.0;
    double sizeInMibibytes = ((double)imgsize)/1048576.0;
    floppyimage = malloc(imgsize);
    memcpy(floppyimage, buffer, 512);
    if ((bpb->totalSectors / bpb->sectorsPerCluster < 4085 || (parsed_args.flags & flag_force_fat12)) && !(parsed_args.flags & flag_force_fat16) ) {
        puts("I: Generating FAT12 image");
        int index = 512;
        if (parsed_args.flags & flag_verbose) {
            if (parsed_args.flags & flag_force_fat12) puts("V: FAT12 forced, ignoring BPB and assuming each FAT is 0x1200 bytes long");
            else printf("V: Size of FAT: %u bytes\n", bpb->sectorsPerFat * bpb->bytesPerSector / bpb->sectorsPerCluster);
        }
        //generate FATs
        for (int table = 0; table < bpb->fatCount; table++) {
            uint32_t* fatptr = (floppyimage + index);
            *fatptr = 0x00FFFFF0;
            index += parsed_args.flags & flag_force_fat12 ? 0x1200 : bpb->sectorsPerFat * bpb->bytesPerSector / bpb->sectorsPerCluster;
        }
    }
    else {
        puts("I: Generating FAT16 image");
        int index = 512;
        if (parsed_args.flags & flag_verbose) {
            if (parsed_args.flags & flag_force_fat16) puts("V: FAT16 forced, ignoring BPB and assuming each FAT is 0x1800 bytes long");
            else printf("V: Size of FAT: %u bytes\n", bpb->sectorsPerFat * bpb->bytesPerSector / bpb->sectorsPerCluster);
        }
        //generate FATs
        for (int table = 0; table < bpb->fatCount; table++) {
            uint32_t* fatptr = (floppyimage + index);
            *fatptr = 0xFFFFFFF0;
            index += parsed_args.flags & flag_force_fat16 ? 0x1800 : bpb->sectorsPerFat * bpb->bytesPerSector / bpb->sectorsPerCluster;
        }

    }
    if (!(parsed_args.flags & flag_verbose))puts("Image generation successful");
    if (parsed_args.flags & flag_verbose) printf("Image generated, size: %u bytes (%f MB, %f MiB)\n", imgsize, sizeInMegabytes, sizeInMibibytes);
    fwrite(floppyimage, bpb->totalSectors * bpb->bytesPerSector, 1, dstfile);
    free(buffer);
    free(floppyimage);
    fclose(dstfile);
}
