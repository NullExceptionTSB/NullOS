@echo off
title Building, please wait..
cls
del nsab.bin
color a
echo BUILD START
echo ==========
C:\Users\NullException\Desktop\Treash\NASM\nasm.exe -f bin bootloader.asm -o nsab.bin
C:\Users\NullException\Desktop\Treash\NASM\nasm.exe -f bin kernelloader.asm -o krnlldr.sys
C:\Users\NullException\Desktop\Treash\NASM\nasm.exe -f bin fat12.asm -o fat12drv.sys
echo Bootloader built succesfuly
echo ========
echo BUILD END
title Build complete
pause
