

all:
	@ nasm -felf64 comm_funcs.s -o comm_funcs.o
	@ nasm -felf64 stage_one.s -o stage_one.o
	@ nasm -felf64 stage_two.s -o stage_two.o
	@ ./x86_64-elf-ld stage_one.o stage_two.o -T linker.ld -o boot.bin
	@ rm *.o
	@ $(MAKE) -s qemu

disk:
	@ dd if=stage_one.bin of=disk.img conv=notrunc bs=446 count=1 >/dev/null 2>&1
	@ dd if=stage_one.bin of=disk.img conv=notrunc bs=1 skip=510 seek=510 >/dev/null 2>&1
	@ dd if=stage_two.bin of=disk.img bs=512 seek=1 count=16 >/dev/null 2>&1
	@ rm *.bin

qemu:
	@ qemu-system-x86_64 -drive file=./boot.bin,format=raw -serial stdio -d int -no-reboot -enable-kvm

