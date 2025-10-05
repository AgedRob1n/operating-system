

all:
	@ nasm -g -felf64 comm_funcs.s -o comm_funcs.o
	@ nasm -g -felf64 stage_one.s -o stage_one.o
	@ nasm -g -felf64 stage_two.s -o stage_two.o
	@ nasm -g -felf64 a20_funcs.s -o a20_funcs.o
	@ ./x86_64-elf-ld *.o -T linker.ld -o boot.bin
	@ $(MAKE) -s qemu
	@ rm *.o

qemu:
	@ qemu-system-x86_64 -drive file=./boot.bin,format=raw -serial stdio -d int -no-reboot -enable-kvm

debug:
	@ nohup qemu-system-x86_64 -drive file=./boot.bin,format=raw -serial stdio -d int -no-reboot -enable-kvm -s -S &
	gdb ./boot.bin
