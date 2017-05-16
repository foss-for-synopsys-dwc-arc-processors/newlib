#include <sys/types.h>
#include <stdlib.h>
#include "common/console_io.h"
#include "write.h"
#include "read.h"

#define STDIN 0

// Pointer to the input stream
unsigned char (*xfunc_in)(void);

_ssize_t _read(
    int fd,
    void *buffer,
    unsigned int count
)
{
    int i = 0;
    char c;
    char *buff = buffer;
    _ssize_t rcount;

    if (fd != STDIN)
	return -1;

    xprintf_setup();

    for (rcount = 0; rcount < count; rcount++) {
        // Get a char from the incoming stream
        c = xfunc_in();
	// End of stream
        if (!c)
	{
	    break;
	}
	else
	{
	    // End of line
	    if (c == '\r')
	    {
		_dw_putc('\n');
		_dw_putc(c);
		buff[i++] = '\n';
		break;
	    }
	    else
	    {
		// Backspace
		if (c == 127 && i != 0) {
		    i--;
		    char *p;
		    // Escape characters for backspace
		    char *str = "\x1B" "[1D" "\x1B" "[0K";
		    for (p = str; *p != 0; p++)
		    {
			_dw_putc(*p);
		    }
		    continue;
		}
		// Other characters
		else
		{
		    buff[i++] = c;
		    _dw_putc(c);
		}
	    }
        }
    }
    // Terminate with a \0
    buff[i] = 0;
    return i;
}
