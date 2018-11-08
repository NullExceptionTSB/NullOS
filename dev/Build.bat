@echo off
title Building, please wait..
cls
color a
echo BUILD START
echo ==========
C:\Users\NullException\Desktop\Treash\NASM\nasm.exe -f bin bootloader.asm -o nsab.bin
echo Bootloader built succesfuly
echo ========
echo BUILD END
pause
