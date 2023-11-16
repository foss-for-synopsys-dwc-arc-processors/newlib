multilibtool_LIBRARIES += %D%/libnsim.a
%C%_libnsim_a_SOURCES = \
	%D%/libcfunc.c \
	%D%/mcount.c \
	%D%/nsim-syscalls.c \
	%D%/sbrk.c

multilibtool_DATA += \
	%D%/crt0.o \
	%D%/gcrt0.o \
	%D%/arc-main-helper.o \
	%D%/nano.specs \
	%D%/nsim.specs

libobjs_a_SOURCES += %D%/crt0.S %D%/gcrt0.S %D%/arc-main-helper.c
