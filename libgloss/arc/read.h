#include <sys/types.h>

#define xdev_in(func) xfunc_in = (unsigned char(*)(void))(func)
extern unsigned char (*xfunc_in)(void);

_ssize_t _read(int fd, void *buffer, unsigned int count);
