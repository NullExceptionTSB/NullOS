BITS 32
ORG 0x10000

main:
	mov eax, 0x01020304
	mov ebx, 0x05060708
	mov ecx, 0x090A0B0C
	mov edx, 0x0D0E0F00
	cli
	hlt
