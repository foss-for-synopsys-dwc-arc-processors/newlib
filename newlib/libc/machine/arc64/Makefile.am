## Process this file with automake to generate Makefile.in

AM_CPPFLAGS = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = $(AM_CPPFLAGS)

noinst_LIBRARIES = lib.a

lib_a_SOURCES =                 \
        memcmp.S                \
        memcmp-stub.c           \
        memcpy.S                \
        memcpy-stub.c           \
        memset.S                \
        memset-stub.c           \
        strlen.S                \
        setjmp.S

lib_a_CCASFLAGS=$(AM_CCASFLAGS)

lib_a_CFLAGS = $(AM_CFLAGS)

