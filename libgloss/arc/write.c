#include <sys/types.h>
#include "write.h"
#include "common/console_io.h"

#define STDOUT 1
#define STDERR 2

// Pointer to the output stream
void (*xfunc_out)(unsigned char);
static char *outptr;

//----------------------------------------------
// Put a character
//----------------------------------------------

void _dw_putc (char c)
{
    // Convert \n ==> \r\n in the output char
    if (c == '\n')
    {
	_dw_putc('\r');
    }

    if (outptr) {
        *outptr++ = (unsigned char)c;
        return;
    }

    if (xfunc_out) xfunc_out((unsigned char)c);
}

_ssize_t _write(
    int fd,
    const void *buffer,
    size_t count
)
{
    _ssize_t wcount;
    char c;

    if (fd != STDOUT && fd != STDERR)
	return -1;

    xprintf_setup();

    for (wcount=0; wcount < count; wcount++) {
	c = * (char *)buffer++;
	if (!c) {
	    break;
	}
	_dw_putc(c);
    }
    return wcount;
}
