OEMLabel               db "NULLOS  "
BytesPerSector         dw 512d          ;512 is sort of the standard for sector sizes
SectorsPerCluster      db 1             ;1 for simplicity
ReservedSectors        dw 1             ;reserved sectors, should be 1 since we have a botsector and nothing else
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
Signature              db 0x29          ;drive signature, 41d = floppy
SerialNumber           dd 0xDEADBEEF    ;disk serial, little endian for DEADBEEF
VolumeLabel            db "NULLOSSOARE"
FileSystem             db "FAT12   "    ;doesn't actually set the filesystem