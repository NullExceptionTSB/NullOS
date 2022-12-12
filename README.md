# NullOS-SOARE

**NOTE: THIS PROJECT IS DEAD IN FAVOR OF A NEW ONE**
i do have half an idea of what i'm doing now

roadmap: 
- [x] Stage 1 FAT12 bootloader
- [x] Stage 2 bootloader (SOARELDR)
- [x] Hardware Abstraction Layer
- [x] GDT and IDT abstraction
- [ ] Memory manager <IN-PROGRESS>
- [ ] Object manager
- [ ] PE Loader
- [ ] Convert HAL to be a module
- [ ] Keyboard IO
- [ ] Disk IO

kind of memory map:\
0x00100000 - Kernel image base address\
0x00010000 - Current base address used for E820 output storage

todo list:
- [x] Rewrite MKIMG
- [ ] Rewrite S1 Bootloader <IN-PROGRESS>
- [ ] Make a stage 1 for FAT16 and FAT32 <IN-PROGRESS>
- [ ] Rewrite SOARELDR <IN-PROGRESS>
- [ ] Multiboot Support

other info in wiki
