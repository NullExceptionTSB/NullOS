OEMLabel               db "SOARE   "
BytesPerSector         dw 512d        
SectorsPerCluster      db 1             
ReservedSectors        dw 1             ;dw 4  WILL NOT WORK! THERE WILL NOT BE ENOUGH SPACE FOR 224 ROOT ENTRIES!
FATCount               db 2             ;number of FATs
RootDirEntryCount      dw 224           ;ammount of maximum root directory entries
TotalSectors           dw 2880          
MediaType              db 0xF0          ;media descriptor byte
SectorsPerFAT          dw 9          
SectorsPerTrack        dw 18             
HeadCount              dw 2             ;number of r/w heads
HiddenSectorCount      dd 0             ;number of hidden sectors
LargeSectorCount       dd 0             ;number of sectors larger then 32 MB
BootDriveNum           db 0             ;drive which holds the boot sector
Reserved               db 0
Signature              db 0x29         ;drive signature, 41d = floppy
SerialNumber           dd 0xDEADBEEF   ;disk serial, little endian for DEADBEEF
VolumeLabel            db "NOOLOSSOARE"
FileSystem             db "FAT12   "    