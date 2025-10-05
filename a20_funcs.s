section .text
[bits 16]

global enable_a20_bios

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


section .data

a20_unsupported db "A20 Line is not Supported",          0
a20_status_err  db "Could not Query A20 Status.",        0
a20_enable_err  db "Could not Enable a20 Through BIOS.", 0
a20_success     db "Succesfully Enabled the A20 Line.",  0

