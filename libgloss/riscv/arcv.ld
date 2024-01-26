/*======================================================================*/
/* ARCV baremetal linker script                                         */
/*======================================================================*/

/*----------------------------------------------------------------------*/
/* Setup                                                                */
/*----------------------------------------------------------------------*/

/* The OUTPUT_ARCH command specifies the machine architecture where the
   argument is one of the names used in the BFD library.  */

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/*----------------------------------------------------------------------*/
/* Sections                                                             */
/*----------------------------------------------------------------------*/

MEMORY {
  ICCM (rx) : ORIGIN = DEFINED (txtmem_addr) ? txtmem_addr : 0x0, LENGTH = DEFINED (txtmem_len) ? txtmem_len : 128K
  DCCM (rwx) : ORIGIN = DEFINED (datamem_addr) ? datamem_addr :0x80000000, LENGTH = DEFINED (datamem_len) ? datamem_len : 128K
}

SECTIONS
{

  /* text: test code section */
  .init :
  {
    KEEP (*(SORT_NONE(.init)))
  } > ICCM

  .text :
  {
    *(.text .stub .text.* .gnu.linkonce.t.*)
    *(.gnu.warning)
  } > ICCM

  .fini :
  {
    KEEP (*(SORT_NONE(.fini)))
  } > ICCM

  PROVIDE (__etext = .);
  PROVIDE (_etext = .);
  PROVIDE (etext = .);

  /* RO Data in ROM  */
  .rodata         : { *(.rodata .rodata.* .gnu.linkonce.r.*) } > ICCM
  .rodata1        : { *(.rodata1) } > ICCM

  /* data segment */
  .data :
  {
    __DATA_BEGIN__ = .;
    *(.data .data.* .gnu.linkonce.d.*)
    SORT(CONSTRUCTORS)
  } > DCCM

  /* Small data segment */
  .sdata :
  {
    __SDATA_BEGIN__ = .;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  } > DCCM
  _edata = .; PROVIDE(edata = .);

  PROVIDE (__preinit_array_start = .);
  .preinit_array  : { *(.preinit_array) } >DCCM
  PROVIDE (__preinit_array_end = .);
  PROVIDE (__init_array_start = .);
  .init_array     : { *(.init_array) } >DCCM
  PROVIDE (__init_array_end = .);
  PROVIDE (__fini_array_start = .);
  .fini_array     : { *(.fini_array) } >DCCM
  PROVIDE (__fini_array_end = .);

  /* bss segment */
  __bss_start = .;
  .sbss : {
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  } > DCCM

  .bss :
  {
    *(.bss .bss.*)
  } > DCCM
  __BSS_END__ = .;
  __global_pointer$ = MIN(__SDATA_BEGIN__ + 0x800,
		          MAX(__DATA_BEGIN__ + 0x800, __BSS_END__ - 0x800));

  /* End of uninitalized data segement */
  _end = .; PROVIDE (end = .);

  /* It's necessary to align stack on 16-bytes boundary since it's a
     maximum possible alignment for RISC-V targets according to
     RISC-V ABI.  */
  __stack_pointer$ = (ORIGIN (DCCM) + LENGTH (DCCM) - 1) & -16;
}

