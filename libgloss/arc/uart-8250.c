/*
 * uart-8250.c -- polling driver for 32-bit 8250 UART.
 * Provides _uart_8250_setup(), _read() and _write(). Please note that
 * _read() and _write() from this file can only be used for console access.
 *
 * Copyright (c) 2021 Synopsys Inc.
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 *
 */

#include <unistd.h>
#include <stdint.h>
#include <stdio.h>
#include <errno.h>

/* Transmit Holding Register.  WO, LCR_DLAB == 0.  */
#define	THR		0x00
/* Receive Buffer Register.  RO, LCR_DLAB == 0.  */
#define	RBR		0x00
/* Divisor Latch Low.  RW, LCR_DLAB == 1.  */
#define	DLL		0x00

/* Divisor Latch High.  RW, LCR_DLAB == 1.  */
#define	DLH		0x04
/* Interrupt Enable Register.  RW, LCR_DLAB == 0.  */
#define	IER		0x04

/* FIFO Control Register.  WO.  */
#define	FCR		0x08
/* Interrupt Identification Register.  RO.  */
#define	IIR		0x08

/* Line Control Register.  RW.  */
#define	LCR		0x0C
/* Divisor Latch Access Bit.  */
#define LCR_DLAB	(1 << 7)
/* Set Break.  */
#define LCR_SB		(1 << 6)
/* Stick Parity.  */
#define LCR_SP		(1 << 5)
/* Even Parity Select.  */
#define LCR_EPS		(1 << 4)
/* Parity Enable.  */
#define LCR_PEN		(1 << 3)
/* Number of Stop Bits.  */
#define LCR_STB		(1 << 2)
/* Data Length Select.
   0x0: 5 data bits per character.
   0x1: 6 data bits per character.
   0x2: 7 data bits per character.
   0x3: 8 data bits per character.  */
#define LCR_DLS1	(1 << 1)
#define LCR_DLS0	(1 << 0)

/* Modem Control Register.  RW.  */
#define	MCR		0x10
/* LoopBack Bit.  */
#define	MCR_LB		(1 << 4)
/* OUT2.  */
#define	MCR_OUT2	(1 << 3)
/* OUT1.  */
#define	MCR_OUT1	(1 << 2)
/* Request To Send.  */
#define	MCR_RTS		(1 << 1)
/* Data Terminal Ready.  */
#define	MCR_DTR		(1 << 0)

/* Line Status Register.  RO.  */
#define	LSR		0x14
/* Receiver FIFO Error.  */
#define	LSR_RFE		(1 << 7)
/* Transmitter Empty.  */
#define	LSR_TEMT	(1 << 6)
/* Transmit Holding Register Empty.  */
#define	LSR_THRE	(1 << 5)
/* Break Interrupt.  */
#define	LSR_BI		(1 << 4)
/* Framing Error.  */
#define	LSR_FE		(1 << 3)
/* Parity Error.  */
#define	LSR_PE		(1 << 2)
/* Overrun Error.  */
#define	LSR_OE		(1 << 1)
/* Data Ready.  */
#define	LSR_DR		(1 << 0)

/* Modem Status Register.  RO.  */
#define	MSR		0x18

/* Main UART control structure.  */
struct _uart_8250 {
  /* Start of UART registers.  */
  volatile char *base;
  /* UART clock.  */
  uint32_t clk;
  /* Baud rate.  */
  uint32_t baud;
  /* If UART registers are mapped to AUX or memory.  */
  int aux_mapped;
  /* If UART is ready to use or not.  */
  int ready;
};

static struct _uart_8250 _uart_8250;

/* Write 32-bit value to the UART register.  */
static inline void
_uart_8250_write_reg (const struct _uart_8250 *uart, uint32_t reg,
		      uint32_t value)
{
  if (uart->aux_mapped)
    __builtin_arc_sr (value, (uint32_t) uart->base + reg);
  else
    *(volatile uint32_t *)(uart->base + reg) = value;
}

/* Read 32-bit value from the UART register.  */
static inline uint32_t
_uart_8250_read_reg (const struct _uart_8250 *uart, uint32_t reg)
{
  if (uart->aux_mapped)
    return __builtin_arc_lr ((uint32_t) uart->base + reg);
  else
    return *(volatile uint32_t *)(uart->base + reg);
}

/* Wait until all flags are set.  */
static inline void
_uart_8250_wait (const struct _uart_8250 *uart, uint32_t reg, uint32_t flags)
{
  while (1)
    {
      if ((_uart_8250_read_reg (uart, reg) & flags) == flags)
	break;
    }
}

/* Get one character from UART.  CR is converted to NL.  */
static int
_uart_8250_getc (const struct _uart_8250 *uart)
{
  char c;

  _uart_8250_wait (uart, LSR, LSR_DR);

  c = _uart_8250_read_reg (uart, RBR);

  if (c == '\r')
    c = '\n';

  return c;
}

/* Put one character to UART.  CR is placed before NL.  */
static void
_uart_8250_putc (const struct _uart_8250 *uart, char c)
{
  if (c == '\n')
    _uart_8250_putc (uart, '\r');

  _uart_8250_wait (uart, LSR, LSR_TEMT | LSR_THRE);

  _uart_8250_write_reg (uart, THR, c);
}

/* Setup UART control structure and following parameters:
     - baudrate if clock and baudrate are passed to function.
     - 8n1 (8 data bits, no parity bit, one stop bit).
     - disable interrupts.
     - disable FIFO.
     - set Request To Send and Data Terminal Ready.
   Parameters:
     base	 start address of UART registers.
     aux_mapped  set if UART registers are mapped to ARC AUX.
     clk	 UART clock frequency.
     baud	 UART baudrate to setup.
   The function returns 0 on success.  */
int
_uart_8250_setup (void *base, int aux_mapped, uint32_t clk, uint32_t baud)
{
  struct _uart_8250 *uart = &_uart_8250;

  uart->base = base;
  uart->aux_mapped = aux_mapped;
  uart->clk = clk;
  uart->baud = baud;

  if (clk && baud)
    {
      uint32_t div;

      div = ((clk + 8 * baud) / baud) / 16;
      _uart_8250_write_reg (uart, LCR, LCR_DLAB);
      _uart_8250_write_reg (uart, DLL, div & 0xFF);
      _uart_8250_write_reg (uart, DLH, div >> 8);
    }

  _uart_8250_write_reg (uart, LCR, LCR_DLS1 | LCR_DLS0);
  _uart_8250_write_reg (uart, IER, 0x0);
  _uart_8250_write_reg (uart, FCR, 0x0);
  _uart_8250_write_reg (uart, MCR, MCR_RTS | MCR_DTR);

  uart->ready = 1;

  return 0;
}

/* _read() is implemented only for stdin.
   Each read character is echoed.  */
ssize_t
_read (int fd, void *buf, size_t count)
{
  struct _uart_8250 *uart = &_uart_8250;
  size_t bytes_read;
  char *buf_char = buf;
  int c;

  if (fd != STDIN_FILENO)
    {
      errno = ENOSYS;
      return -1;
    }

  if (!uart->ready)
    {
      errno = EIO;
      return -1;
    }

  bytes_read = 0;
  c = EOF;
  /* Break on '\n' to simulate readline behavior.  */
  while (bytes_read != count && c != '\n')
    {
      c = _uart_8250_getc (uart);
      if (c == EOF)
	break;

      /* Echo character to the console.  */
      _uart_8250_putc (uart, c);

      buf_char[bytes_read] = c;
      bytes_read++;
    }

  return bytes_read;
}

/* _write() is implemented only for stdout and stderr.  */
ssize_t
_write (int fd, const char *buf, size_t nbyte)
{
  struct _uart_8250 *uart = &_uart_8250;
  uint32_t bytes_written;

  if (fd != STDOUT_FILENO && fd != STDERR_FILENO)
    {
      errno = ENOSYS;
      return -1;
    }

  if (!uart->ready)
    {
      errno = EIO;
      return -1;
    }

  bytes_written = 0;
  while (bytes_written != nbyte)
    {
      _uart_8250_putc (uart, buf[bytes_written]);
      bytes_written++;
    }

  return bytes_written;
}
