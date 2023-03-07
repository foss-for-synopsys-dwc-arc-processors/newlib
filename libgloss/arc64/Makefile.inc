multilibtool_LIBRARIES += %D%/libnsim.a
%C%_libnsim_a_SOURCES = \
	%D%/libcfunc.c \
	%D%/nsim-syscall.c \
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
        %D%/hl/hl_gw.c \
        %D%/hl/hl_api.c \
        %D%/hl/hl_open.c \
        %D%/hl/hl_close.c \
        %D%/hl/hl_read.c \
        %D%/hl/hl_write.c \
        %D%/hl/hl_lseek.c \
        %D%/hl/hl_unlink.c \
        %D%/hl/hl_isatty.c \
        %D%/hl/hl_clock.c \
        %D%/hl/hl_gettimeofday.c \
        %D%/hl/hl_argc.c \
        %D%/hl/hl_argv.c \
        %D%/hl/hl_exit.c

multilibtool_DATA += \
	%D%/crt0.o \
	%D%/crtn.o \
	%D%/crti.o \
	%D%/arc-main-helper.o \
	%D%/nsim.specs \
	%D%/hl.specs \
	%D%/qemu.specs
libobjs_a_SOURCES += %D%/crt0.S %D%/crtn.S %D%/crti.S %D%/arc-main-helper.c
