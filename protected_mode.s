[bits 32]
section .text

global protected_mode_main

protected_mode_main:
  mov byte [foreground_color], 0x0F
  push prot_mode_str
  call print_ln
  push test_str
  call print_str
  jmp $

print_ln:
  mov si, [esp + 4]
  call print_str_backend
  call new_line
  ret 4

print_str:
  mov si, [esp + 4]
  call print_str_backend
  ret 4

print_str_backend:
  .loop:
    lodsb
    or al, al
    jz .end
    call print_char
    jmp .loop
  .end:
    ret

print_char:
  mov ecx, 0x0B8000
  add cx, [cursor_pos]
  add cx, [cursor_pos]
  mov ah, [foreground_color]
  mov [ecx], ax
  call increment_cursor_pos
  ret

set_cursor_pos:
  push dx
  push ax
  mov dx, 0x03D4
  mov al, 0x0F
  out dx, al

  inc dx
  mov al, byte [cursor_pos]
  out dx, al

  dec dx
  mov dx, 0x03DF
  mov al, 0x0E
  out dx, al

  inc dx
  mov al, byte [cursor_pos + 1]
  out dx, al

  pop dx
  pop ax
  ret

new_line:
  .loop:
    mov ax, [cursor_pos]
    mov bl, 80
    div bl
    cmp ah, 0
    je .end
    inc word [cursor_pos]
    jmp .loop
  .end:
    call set_cursor_pos
    ret


increment_cursor_pos:
  inc word [cursor_pos]
  call set_cursor_pos
  ret

section .data

screen_width equ 80
cursor_pos dd 0
foreground_color db 0
vga_pos dd 0x0B8000

prot_mode_str db "Successfully entered 32 bit mode.", 0
test_str      db "Hello, World!", 0
