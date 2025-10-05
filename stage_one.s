; org 0x7C00
section .text
bits 16

jmp _start

clear_screen:
  mov ah, 0x00
  mov al, 0x03
  int 0x10
  ret

establish_serial_port:
  mov ah, 0x00
  mov al, 0b11100011
  mov dx, 0x0000
  int     0x14
  ret

; Expects AL to be set
send_char:
  mov ah, 0x01
  xor dx, dx
  int 0x14
  ret

send_ln:
  mov al, 13
  call send_char
  mov al, 10
  call send_char
  ret

extern send_str

read_disk:
  mov ah, 0
  int 0x13
  mov ax, 0x07E0
  mov es, ax
  mov bx, 0x0000
  mov ah, 0x02
  mov al, [stage_two_sectors]
  mov ch, 0x00
  mov cl, 0x02
  mov dh, 0x00
  mov dl, [disk]
  mov bx, 0x00

  int 0x13
  push file_success
  call send_str
  ret

_start:
  call clear_screen
  call establish_serial_port
  call read_disk
  mov al, [disk] ; Move Disk Identifier to al
  mov ah, [stage_two_sectors] ; Move the sector count to ah
  jmp 0x07E0:0x00
  jmp $

new_line          db                             0
disk_success_str  db "Disk Found",               0
file_err          db "Couldn't Open Disk.",      0
file_success      db "Successfully Opened Disk", 0
disk              db 0x80
stage_two_sectors db 0x08


