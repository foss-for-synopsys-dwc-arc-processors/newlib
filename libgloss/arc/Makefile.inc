multilibtool_LIBRARIES += %D%/libnsim.a
%C%_libnsim_a_SOURCES = \
	%D%/libcfunc.c \
	%D%/mcount.c \
	%D%/nsim-syscalls.c \
	%D%/sbrk.c

multilibtool_LIBRARIES += %D%/libqemu.a
%C%_libqemu_a_SOURCES = \
	%D%/qemu-write.c \
	%D%/qemu-stub.c \
	%D%/sbrk.c

multilibtool_LIBRARIES += %D%/libhl.a
%C%_libhl_a_CPPFLAGS = -I$(srcdir)/%D%
%C%_libhl_a_SOURCES = \
	%D%/arc-timer.c \
	%D%/hl-stub.c \
	%D%/hl-setup.c \
	%D%/libcfunc.c \
	%D%/sbrk.c \
	%D%/mcount.c \
        %D%/hl/hl_gw.c \
        %D%/hl/hl_api.c \
        %D%/hl/hl_open.c \
        %D%/hl/hl_close.c \
        %D%/hl/hl_read.c \
        %D%/hl/hl_write.c \
        %D%/hl/hl_lseek.c \
        %D%/hl/hl_unlink.c \
        %D%/hl/hl_isatty.c \
        %D%/hl/hl_fstat.c \
        %D%/hl/hl_clock.c \
        %D%/hl/hl_gettimeofday.c \
        %D%/hl/hl_argc.c \
        %D%/hl/hl_argv.c \
        %D%/hl/hl_exit.c


multilibtool_LIBRARIES += %D%/libdw_uart.a
%C%_libdw_uart_a_CPPFLAGS = -I$(srcdir)/%D% -I$(srcdir)/%D%/dw_uart/
%C%_libdw_uart_a_SOURCES = \
	%D%/write.c \
	%D%/read.c \
	%D%/stub.c \
	%D%/sbrk.c \
	%D%/dw_uart/arc/arc_exc_asm.S \
        %D%/dw_uart/arc/arc_exception.S \
        %D%/dw_uart/board/board.c \
	%D%/dw_uart/board/emsk/uart/dw_uart_obj.c \
        %D%/dw_uart/common/console_io.c \
        %D%/dw_uart/device/designware/uart/dw_uart.c

multilibtool_DATA += \
	%D%/crt0.o \
	%D%/gcrt0.o \
	%D%/arc-main-helper.o \
	%D%/nano.specs \
	%D%/nsim.specs \
	%D%/hl.specs \
	%D%/qemu.specs \
	%D%/emsk_em9d.specs \
        %D%/emsk_em11d.specs \
	%D%/emsk_em11d.x \
	%D%/emsk_em9d.x
libobjs_a_SOURCES += %D%/crt0.S %D%/gcrt0.S %D%/arc-main-helper.c
