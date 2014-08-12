## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

noinst_LIBRARIES = lib.a

lib_a_SOURCES = 	\
	memcmp.S	\
	memcmp-601.S	\
	memcpy.S 	\
	memcpy-601.S 	\
	memcpy-700.S 	\
	memcpy-archs.S	\
	memset-601.S 	\
	memset.S 	\
	setjmp.S 	\
	strcmp.S 	\
	strchr.S 	\
	strchr-601.S	\
	strchr-700.S	\
	strcpy.c 	\
	strcpy-600.S 	\
	strcpy-601.S 	\
	strcpy-700.S 	\
	strlen.S 	\
	strlen-600.S 	\
	strlen-601.S 	\
	strncpy.S	\
	strncpy-601.S

lib_a_CCASFLAGS=$(AM_CCASFLAGS)
lib_a_CFLAGS = $(AM_CFLAGS)

ACLOCAL_AMFLAGS = -I ../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

pdf:
install-pdf:
