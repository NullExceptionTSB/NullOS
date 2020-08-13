#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include "fat12.h"
#include "mkimg.h"

unsigned int verbose;

void fail(char* string) {
    printf("F: ");
    puts(string);
    exit(1);
}

void warning(char* string) {
    printf("W: ");
    puts(string);
}

void verbprint(char* str) {
    if (verbose) {
        printf("V: ");
        puts(str);
    }
}

parsedargs parse_args(char* argv[], int argc) {
    parsedargs parsed_args;
    argflags flags = 0;
    parsed_args.fileSize = 1440;
    parsed_args.chs.heads = 16;
    parsed_args.chs.sectorsPerTrack = 63;
    if (argc > 1) {
        for (int argi = 1; argi < argc; argi++) {
            if (argv[argi][0] == '-') {
                int arglen = strlen(argv[argi]);
                if (arglen < 2) break;
                for (int i = 1; i < arglen; i++){
                    switch (argv[argi][i]) {
                        case 'H':
                            parsed_args.chs.heads = strtoul(argv[argi+1], NULL, 10);
                            break;
                        case 'C':
                            parsed_args.chs.sectorsPerTrack = strtoul(argv[argi+1], NULL, 10);;
                            break;
                        case 'p':
                            flags |= flag_partitioned;
                            parsed_args.mbrFile = argv[argi+1];
                            break;
                        case 's':
                            parsed_args.fileSize = strtoul(argv[argi+1], NULL, 10);
                            if (!parsed_args.fileSize) fail("Size null or invalid");
                            break;
                        case 'h':
                            fail("Help specified\n\n-f: Force FAT12, cannot use with -F\n-F: Force FAT16, cannot use with -f\n-h: Show this message\n-i: Specifies the next argument is the path to the bootsector file (used as partition 0's VBR in partitioned images) [this arg is mandatory]\n-o: Specifies the next argument is the output [this arg is mandatory]\n-v: Verbose mode\n-p: Partition disk, the next parameter is interpreted as the path to the MBR file\n-s: Specify file size, the next parameter is interpreted as the desired image size in kB. Default size is 1440 kiB\n-S: Specify sectors per track, the next parameter is interpreted as the desired sectors per track [default: 63]\n-H: Specify the number of heads [default: 16]");
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
                            /*
                        case 'c':
                            flags |= flag_noverif;
                            break;
                            */
                    }
                }
            }
        }
    }
    if (argc == 1) 
        fail("Invalid parameters\nRun mkimg -h for more information");
    if ((flags & flag_force_fat12) && (flags & flag_force_fat16)) 
        fail("Invalid combination of args");
    if (!(flags & flag_input))
        fail("Input file not specified");
    if (!(flags & flag_output))
        fail("Output file not specified");

    parsed_args.flags = flags;
    return parsed_args;
}

//calculates CHS values from "heads", "sectorsPerTrack" and the image size in kilobytes
//assuming sectors are 512 bytes
void fillCHS(chsA chs, unsigned int imgSize) {
    if (!chs.sectorsPerTrack || !chs.heads) return;
    int lba = imgSize*2;
    chs.cylinders = lba / chs.sectorsPerTrack;
    chs.sectors = lba % chs.sectorsPerTrack;
    chs.headsPerCylinder = chs.cylinders / chs.heads;
}
//returns the sector ammount
int getClusterSize(unsigned int imgSize, int fatType) {
    switch (fatType) {
        case 12:
            return 1;
            break;
        case 16:
            if (imgSize < 8400) 
                return 1;
            else if (imgSize < 32680)
                return 2;
            else if (imgSize < 262144)
                return 4;
            else if (imgSize < 524288)
                return 8;   
            else if (imgSize < 1048576)
                return 16;
            else if (imgSize < 2097152)
                return 32;
            else if (imgSize < 4194304)
                return 64;
            else return 0;
            break;
        case 32:
            if (imgSize < 66600) 
                return 0;
            else if (imgSize < 532480)
                return 1;
            else if (imgSize < 16777216)
                return 8;
            else if (imgSize < 33554432)
                return 16;
            else if (imgSize < 67108864)
                return 32;
            else return 64;
            break;
        default: return 0;
    }
}

int getFATType(bios_parameter_block bpb) {
    //go fuck yourself, microsoft
    if      (!strncmp("FAT12", bpb.filesystem, 5)) return 12;
    else if (!strncmp("FAT16", bpb.filesystem, 5)) return 16;
    else if (!strncmp("FAT32", bpb.filesystem, 5)) return 32;
    else return 0;
}

partition generatePartition(chsA start, chsA end, bootflag bootFlag, int sysid) {

}

int generateFATs(int fatSize, int fatType, unsigned int startOffset, int fatCount, unsigned char* image) {
    switch (fatType) {
        case 12:
            for (int i = 0; i < fatCount; i++) {
                *((image + (startOffset + (i * fatSize))) + 0) = 0xf0;
                *((image + (startOffset + (i * fatSize))) + 1) = 0xff;
                *((image + (startOffset + (i * fatSize))) + 2) = 0xff;
            }
            break;
        case 16:
            for (int i = 0; i < fatCount; i++) 
                *(unsigned int*)(image + (startOffset + (i * fatSize) - 1))  = 0xFFFFFFF8;
            break;
        case 32:
            for (int i = 0; i < fatCount; i++) {
                *(unsigned int*)(image + (startOffset + (i * fatSize + 0) - 1)) = 0x0FFFFFF8;
                *(unsigned int*)(image + (startOffset + (i * fatSize + 4) - 1)) = 0x0FFFFFFF;
                *(unsigned int*)(image + (startOffset + (i * fatSize + 8) - 1)) = 0x0FFFFFF8;
            }
            break;
        default:
            fail("that's not a fat type retard");
    }
}

int main(int argc, char* argv[]) {
    //parse arguments
    parsedargs parsed_args = parse_args(argv, argc);
    puts("mkimg 2.0 by NullException, created as part of SOARE/NullOS");
    //enable verbose mode and declare file handles
    parsed_args.fileSize *= 1024;
    verbose = parsed_args.flags & flag_verbose;
    FILE* srcfile;
    FILE* dstfile;
    FILE* mbrfile;
    //open file handles
    srcfile = fopen(parsed_args.inputFile, "r");
    if (!srcfile) fail("Could not open source file");
    //if dest file exists, overwrite it 
    if (access(parsed_args.outputFile, F_OK) != -1)
        if (remove(parsed_args.outputFile)) fail("Cannot overwrite output file");
        
    dstfile = fopen(parsed_args.outputFile, "w");
    if (!dstfile) fail("Could not create output file");

    if (parsed_args.flags & flag_partitioned) {
        verbprint("Creating partitioned disk");
        fail("Disk partitioning currently unsupported");
    }
    else {
        verbprint("Creating raw (unpartitioned) disk");

        size_t inbuffer_size;
        unsigned short* ptrBootsig;
        bios_parameter_block* bpb;
        fseek(srcfile, 0, SEEK_END);
        inbuffer_size = ftell(srcfile);
        if (inbuffer_size > parsed_args.fileSize) fail("Bootsector data larger then desired image size");
        //load input
        byte* buffer = malloc(parsed_args.fileSize);
        byte* inbuffer = malloc(inbuffer_size);
        memset(buffer, 0, parsed_args.fileSize);
        fseek(srcfile, 0, SEEK_SET);
        fread(inbuffer, inbuffer_size, 1, srcfile);
        memcpy(buffer, inbuffer, inbuffer_size);
        ptrBootsig = ((void*)buffer) + 510;
        bpb = (bios_parameter_block*)buffer;
        fclose(srcfile);
        free(inbuffer);
        bpb->fatCount = 2;
        //determine if FAT type can be determined
        if (bpb->signature != 0x28 && bpb->signature != 0x29) fail("Extended BPB not found");
        //determine FAT type
        int fatType = 0;
        if (parsed_args.flags & flag_force_fat12) {
            fatType = 12;
            verbprint("Forcing FAT12");
        }
        else if (parsed_args.flags & flag_force_fat16) {
            fatType = 16;
            verbprint("Forcing FAT16");
        }  
        else {
            fatType = getFATType(*bpb);
            switch (fatType) {
                case 12:
                    verbprint("FAT12 Detected");
                    break;
                case 16:
                    verbprint("FAT16 Detected");
                    break;
                case 32:
                    verbprint("FAT32 Detected");
                    fail("FAT32 currently unsupported");
                default:
                    fail("Failed to autodetect file system");
            }
        }
        //determine cluster size
        int clusterSize = getClusterSize(parsed_args.fileSize, fatType);
        clusterSize *= 512;
        if (!clusterSize) fail("Cannot use file system with this image size");
        if (verbose) printf("V: Cluster size calculated as %u sectors\n", clusterSize);
        //calculate size of FATs
        int data = -2;
        int fats = 0;
        int fds = (parsed_args.fileSize / 512) - bpb->reservedSectors;
        switch (fatType) {
            case 12:
                fds -=(bpb->rootDirectoryEntries * 32)/512;
                do {
                    data += clusterSize * 2;
                    fats += 6;
                    fds -= clusterSize * 2 + 6;
                } while (fds > 0);
                break;
            case 16:
                fds -=(bpb->rootDirectoryEntries * 32)/512;
                do {
                    data += clusterSize;
                    fats += 4;
                    fds -= clusterSize + 4;
                } while (fds > 0);
                break;
            case 32:
                do {
                    data += clusterSize;
                    fats += 8;
                    fds -= clusterSize + 4;
                } while (fds > 0);
                break;
            default:
                fail("Fuck off with your cosmic rays");
        }
        if (verbose) printf("V: Size of both FATS calculated as %u sectors\n", fats);
        //set bpb info
        bpb->bytesPerSector = 512;
        bpb->sectorsPerCluster = clusterSize / 512;
        if (verbose) printf("V: ClusterSize = %u\n  ", bpb->sectorsPerCluster);
        bpb->reservedSectors = inbuffer_size / 512 + (inbuffer_size % 512 ? 1 : 0);
        if (verbose) printf("V: ReservedSectors = %u\n  ", bpb->reservedSectors);
        bpb->fatCount = 2;
        bpb->totalSectors = parsed_args.fileSize / 512 < 65535 ? parsed_args.fileSize / 512: 0;
        bpb->largeSectors = parsed_args.fileSize / 512 < 65535 ? 0 : parsed_args.fileSize / 512;
        if (verbose) printf("V: TotalSectors = %u\nV: LargeSectors = %u\n", bpb->totalSectors, bpb->largeSectors);
        bpb->sectorsPerTrack = parsed_args.chs.sectorsPerTrack;
        bpb->headCount = parsed_args.chs.heads;
        bpb->sectorsPerFat = fats/2;
        //generate FATs
        generateFATs(fats * 512 / 2, fatType, bpb->reservedSectors * 512, 2, buffer);
        fwrite(buffer, parsed_args.fileSize, 1, dstfile);
        free(buffer);
        fclose(dstfile);
    }


}
