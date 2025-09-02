bits 16

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
db 0 ; without this line the next string doesn't work
gdt_success_str       db  "GDT succesfully created.",         0

mem_entry_num         db  0x00
mem_map_addr          dw  0x8000
cpuid_test_bit        dd  1 << 21
long_test_bit         dd  1 << 31
disk                  equ  0x00
sector_count          equ  0x00

section .text
extern send_str

stage_two:
  push success_msg
  call send_str
  
  call detect_memory
  
  push det_long_mode
  call send_str
  
  push long_mode_str
  call send_str

  push det_cpuid
  call send_str

  call check_cpuid_support
  call check_long_mode_support
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
  push protected_mode_str
  call send_str
  push creating_gdt_str
  call send_str
  cli
  call create_gdt
  push gdt_success_str
  call send_str

  mov eax, cr0
  or al, 1
  mov cr0, eax
  jmp 0x08:protected_mode

  ret


gdt:
  .null:
    dq 0
  .code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0b10011011
    db 0b11001111
  .data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0b10010011
    db 0b11001111
  .end:

check_a20_line:
  pushf
  push es
  push ds
  push di
  push si
  xor ax, ax
  mov es, ax
  not ax
  mov ds, ax

create_gdt:
  gdtr dw 0
       dd 0
  mov ax,  [esp+4]
  mov [gdtr], ax
  mov eax, [esp+8]
  add eax, [esp+12]
  mov [gdtr + 2], eax
  lgdt [gdtr]
  ret

detect_memory:
  xor ebx, ebx
  xor bp, bp

  mov di, [mem_map_addr]
  add di, 4

  mov eax, 0xE820
  mov edx, 0x0534D4150

  mov byte [es:di + 20], 0x01
  mov ecx, 24
  int 0x15

  jc .unsupported_call
  mov edx, 0x0534D4150
  cmp eax, edx
  jne .misc_err
  test ebx, ebx
  je .misc_err
  jmp .success

  .unsupported_call:
    push unsupported_str
    call send_str
    stc
    ret
  .misc_err:
    push misc_err
    call send_str
    stc
    ret

  .success:
    push mem_start_str
    call send_str
    jcxz .test
    cmp cl, 20
    jbe .no_text
    test byte [es:di + 20], 0x01
    ret

  .loop:
    mov eax, 0xE820
    mov [es:di + 20], dword 0x01
    mov ecx, 24
    int 0x15
    jmp .finish
    mov edx, 0x0534D4150
  .no_text:
    mov ecx, [es:di + 8]
    mov ecx, [es:di + 12]
    jz .test
    inc bp
    add di, 24

  .test:
    test ebx, ebx ; If EBX == 0  leave loop
    jne .loop
  .finish:
    mov [es:mem_map_addr], bp
    clc
    push mem_fin_str
    call send_str
    ret


bits 32
protected_mode:
  jmp protected_mode
  ret
