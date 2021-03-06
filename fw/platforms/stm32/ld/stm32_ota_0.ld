/*
 * Copyright (c) 2014-2018 Cesanta Software Limited
 * All rights reserved
 */

ENTRY(stm32_entry)

/* Initial stack location and size (before RTOS). */
_stack = SRAM_BASE_ADDR + SRAM_SIZE;
_stack_size = 0x400;

MEMORY {
  FLASH_BL  (rx)  : ORIGIN = FLASH_BASE_ADDR, LENGTH = FLASH_BL_SIZE
  FLASH_BLC (rx)  : ORIGIN = FLASH_BASE_ADDR + FLASH_BL_SIZE, LENGTH = FLASH_S0_SIZE
  FLASH_FS (r)   : ORIGIN = FLASH_BASE_ADDR + FLASH_BL_SIZE + FLASH_BLC_SIZE, LENGTH = FLASH_FS_SIZE
  FLASH_CS (rx)  : ORIGIN = FLASH_BASE_ADDR + FLASH_BL_SIZE + FLASH_BLC_SIZE + FLASH_FS_SIZE,
                   LENGTH = FLASH_SIZE - (FLASH_BL_SIZE + FLASH_BLC_SIZE + FLASH_FS_SIZE)
  SRAM     (rwx) : ORIGIN = SRAM_BASE_ADDR,  LENGTH = SRAM_SIZE
}

/* Define output sections */
SECTIONS {
  .bool_loader : {
    KEEP(*(.bl_bin))
  } > FLASH_BL

  .fs_img : {
    KEEP(*(.fs_img))
  } > FLASH_FS

  .text : {
    . = ALIGN(256);  /* Vectors must be aligned to 0x100 */
    KEEP(*(.flash_int_vectors))
    *(.text SORT(.text.*))
    *(.eh_frame)
    KEEP (*(.init))
    KEEP (*(.fini))
    . = ALIGN(4);
  } > FLASH_CS

  .ARM.extab   : { *(.ARM.extab* .gnu.linkonce.armextab.*) } > FLASH_CS
  .ARM : {
    __exidx_start = .;
    *(.ARM.exidx*)
    __exidx_end = .;
  } > FLASH_CS

  .preinit_array     :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  } > FLASH_CS
  .init_array :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
  } > FLASH_CS
  .fini_array :
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    PROVIDE_HIDDEN (__fini_array_end = .);
  } > FLASH_CS

  .rodata : {
    *(.rodata SORT(.rodata.*))
  } > FLASH_CS

  .data : {
    _data_start = .;
    . = ALIGN(256);  /* Vectors must be aligned to 0x100 */
    KEEP(*(.ram_int_vectors))
    *(.data SORT(.data.*))
    *(.RamFunc SORT(.RamFunc.*))
    _data_end = .;
  } > SRAM AT > FLASH_CS
  _data_flash_start = LOADADDR(.data);

  .bss : {
    _bss_start = .;
    *(.bss SORT(.bss.*))
    *(COMMON)
    . = ALIGN(4);
    _bss_end = .;
  } > SRAM

  /* For now, max size of no-cache region is 1K */
  .nocache : {
    . = ALIGN(NOCACHE_SIZE);
    __nocache_start__ = .;
    *(.nocache)
    . = ALIGN(NOCACHE_SIZE);
    __nocache_end__ = .;
  } > SRAM

  .heap : {
    . = ALIGN(8);
    _heap_start = .;
    . = . + (LENGTH(SRAM) - SIZEOF(.data) - SIZEOF(.bss) - SIZEOF(.nocache) - _stack_size);
    . = ALIGN(8);
    _heap_end = .;
  } > SRAM

  /* Remove information from the standard libraries */
  /DISCARD/ :
  {
    libc.a ( * )
    libm.a ( * )
    libgcc.a ( * )
  }

  .ARM.attributes 0 : { *(.ARM.attributes) }
}
