section .text
[bits 16]

global enable_a20_bios
global enable_long_mode

extern send_str

enable_a20_bios:
  mov ax, 0x2403
  int 0x15

  ; All of the a20 gate functions signal status through the CF and AH registers
  ; If the status is one, the operation failed
  ; When you call jb without a comparison, it jumps if c = 1

  jb .a20_not_supported
  cmp ah, 1
  je .a20_not_supported

  mov ax, 0x2402
  int 0x15

  jb .a20_status_err
  cmp ah, 1
  je .a20_status_err
  
  cmp al, 1
  je .a20_enabled

  mov ax, 0x2401
  int 0x15
  jb .a20_enable_err
  cmp ah, 1
  je .a20_enable_err

  jmp .a20_enabled

  .a20_not_supported:
    push a20_unsupported
    jmp .err
  .a20_enable_err:
    push a20_enable_err
    jmp .err
  .a20_status_err:
    push a20_status_err
    jmp .err
  .a20_enabled:
    push a20_success
    call send_str
    ret
  .err:
    xor ax, ax
    call send_str
    ret

global check_cpuid_support
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

global check_long_mode_support
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

global check_extended_support
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

; -----------------------------------
; -     Protected Mode routines     -
; -----------------------------------
enter_long_mode:
  

section .data

a20_unsupported       db "A20 Line is not Supported",          0
a20_status_err        db "Could not Query A20 Status.",        0
a20_enable_err        db "Could not Enable a20 Through BIOS.", 0
a20_success           db "Succesfully Enabled the A20 Line.",  0

extended_unsupported  db  "Extended Mode is Unsupported.",     0
extended_supported    db  "Extended Mode is Supported.",       0
cpuid_supported       db  "CPUID Supported.",                  0
cpuid_unsupported     db  "CPUID Not Supported.",              0
long_mode_supported   db  "Long Mode Supported.",              0
long_mode_unsupported db  "Long Mode Unsupported.",            0

CR0_PAGING_FLAG equ 1 << 31
PL4_TABLE_ADDR  equ 0x1000
PAGE_TABLE_SIZE equ 4096

