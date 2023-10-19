libc_a_SOURCES += \
	%D%/memcmp-stub.c %D%/memchr-stub.c \
	%D%/memchr.S      %D%/memcmp.S \
	%D%/strlen-stub.c %D%/strcpy-stub.c %D%/strcat-stub.c %D%/strchr-stub.c \
	%D%/strlen.S      %D%/strcpy.S      %D%/strcat.S      %D%/strchr.S \
	%D%/memmove.S %D%/memmove-stub.c %D%/memset.S %D%/memcpy-asm.S %D%/memcpy.c \
	%D%/strcmp.S %D%/setjmp.S %D%/ieeefp.c %D%/ffs.c
