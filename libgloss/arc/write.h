#include <sys/types.h>

#define xdev_out(func) xfunc_out = (void(*)(unsigned char))(func)
extern void (*xfunc_out)(unsigned char);
extern void _dw_putc (char c);

extern _ssize_t _write(int fd, const void *buffer, unsigned int count);
