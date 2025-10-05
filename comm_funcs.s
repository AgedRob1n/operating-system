bits 16

section .text

global increment_cursor_pos
global print_char
global print_str
global serial_send_char
global serial_send_str
global print_ln
global send_str

increment_cursor_pos:
  cmp byte [cursor_col], (VGA_WIDTH - 1)
  je .new_line

  .inc_update_pos:
    mov ah, 0x02
    inc byte [cursor_col]
    mov dh, [cursor_row]
    mov dl, [cursor_col]
    int 0x10
    ret
  .new_line:
    inc byte [cursor_row]
    mov byte [cursor_col], 0
    jmp .inc_update_pos

print_char:
  mov ah, 0x0A
  mov bx, 0x000F
  mov cx, 0x01
  int 0x10
  call increment_cursor_pos
  ret

print_str:
  .print_str_loop:
    lodsb
    or al, al
    jz .print_str_end
    call print_char
    jmp .print_str_loop
  .print_str_end:
    call print_ln
    ret

print_ln:
  mov byte [cursor_col], 0
  inc byte [cursor_row]
  cmp byte [cursor_row], VGA_HEIGHT
  je .scroll
  .update_pos:
    mov ah, 0x02
    xor bx, bx
    mov dh, [cursor_row]
    mov dl, [cursor_col]
    int 0x10
    ret
  .scroll:
    mov ax, 0x0701
    mov bh, 0x00
    xor cx, cx
    mov dh, VGA_WIDTH
    mov dl, VGA_HEIGHT
    int 0x10
    dec byte [cursor_row]
    ret

serial_send_char:
  mov ah, 0x01
  xor dx, dx
  int 0x14
  ret

send_str:
  mov si, [esp+2]
  call print_str
  mov si, [esp+2]
  call serial_send_str
  ret 2


serial_send_str:
  .loop:
    lodsb
    or al, al
    jz .end
    call serial_send_char
    jmp .loop
  .end:
    mov al, 13
    call serial_send_char
    mov al, 10
    call serial_send_char
    ret

section .data
cursor_col            db  0x00
cursor_row            db  0x00
VGA_WIDTH             equ 80
VGA_HEIGHT            equ 25

