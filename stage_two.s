bits 16

section .text
extern send_str
extern serial_send_str
extern enable_a20_bios

stage_two:
  push success_msg
  call send_str
  
  ; call detect_memory when implemented
  
  push det_long_mode
  call send_str
  call check_long_mode_support
  
  push long_mode_str
  call send_str

  push det_cpuid
  call send_str
  call check_cpuid_support

  call enter_protected_mode

  jmp $

check_cpuid_support:
  pushfd
  pushfd
  xor dword [esp], 0x00200000
  popfd
  pushfd
  pop eax
  xor eax, [esp]
  popfd
  and eax, 0x00200000
  jz .hang
  push cpuid_supported
  call send_str
  ret
  .hang:
    push cpuid_unsupported
    call send_str
    jmp $

check_long_mode_support:
  push ebx
  call check_extended_support
  mov eax, 0x80000001
  cpuid
  shr edx, 29
  and edx, 1
  jz .hang
  push long_mode_supported
  call send_str
  pop ebx
  ret
  .hang:
    push long_mode_unsupported
    call send_str
    jmp $

check_extended_support:
  mov eax, 0x80000000
  cpuid
  cmp eax, 0x80000000
  jbe .hang
  push extended_supported
  call send_str
  ret
  .hang:
    push extended_unsupported
    call send_str
    jmp $

enter_protected_mode:
  call enable_a20_bios

  push protected_mode_str
  call send_str
  push creating_gdt_str
  call send_str
  call create_gdt
  push gdt_success_str
  call send_str
  cmp ax, 1
  je .hang

  mov eax, cr0
  or eax, 1
  mov cr0, eax
  jmp 0x08:protected_mode
  jmp $

  ret

  .hang:
    jmp $


gdt:
  .null:
    dq 0
  .code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x9B
    db 0xCF
    db 0x00
  .data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92 ; 10010010
    db 0xCF
    db 0x00
  .end:

gdt_description:
  dw gdt.end - gdt
  dd gdt

create_gdt:
  cli
  xor ax, ax
  mov ds, ax
  lgdt [gdt_description]
  ret

bits 32
protected_mode:
  jmp $
  mov ax, 0x08
  mov ds, ax
  mov ss, ax
  mov esp, 0x090000
  ret


section .data
success_msg           db  "Succesfully Entered Second Stage", 0
unsupported_str       db  "Unsupported Function Call",        0
mem_start_str         db  "Probing Memory...",                0
mem_fin_str           db  "Memory Probing Finished.",         0
misc_err              db  "Misc. Error",                      0
long_mode_str         db  "Entering Long Mode...",            0
protected_mode_str    db  "Entering Protected Mode...",       0
det_long_mode         db  "Detecting Long Mode Support...",   0
det_cpuid             db  "Detecting CPUID Support...",       0
cpuid_supported       db  "CPUID Supported.",                 0
cpuid_unsupported     db  "CPUID Not Supported.",             0
long_mode_supported   db  "Long Mode Supported.",             0
long_mode_unsupported db  "Long Mode Unsupported.",           0
long_mode_success_str db  "Succesfully Entered Long Mode.",   0
extended_unsupported  db  "Extended Mode is Unsupported.",    0
extended_supported    db  "Extended Mode is Supported.",      0
creating_gdt_str      db  "Creating GDT...",                  0
db 0
gdt_success_str       db  "GDT succesfully created.",         0

mem_entry_num         db  0x00
mem_map_addr          dw  0x8000
cpuid_test_bit        dd  1 << 21
long_test_bit         dd  1 << 31
disk                  equ  0x00
sector_count          equ  0x00


