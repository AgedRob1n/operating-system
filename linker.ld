OUTPUT_FORMAT(binary)

SECTIONS {
  . = 0x7C00;
  .stage_one : AT(0x7C00) SUBALIGN(4) {
    stage_one.o(.text)
    stage_one.o(.*)
  }

  . = 0x7DFE;
  .signature : {
    SHORT(0xAA55);
  }

  . = 0x7E00;
  .stage_two : AT(0x7E00) SUBALIGN(4) {
    stage_two.o(.text)
    stage_two.o(.data)
    comm_funcs.o(.text)
    comm_funcs.o(.data)
  }
}

