#include <stdint.h>
#include <stdbool.h>
#include <time.h>
#include <sys/types.h>
#include <sys/times.h>
#include <machine/syscall.h>
#include "semihost_syscall.h"

clock_t
_times(struct tms *buf)
{
  static bool initialized = false;
  static clock_t semihosting_tick_freq = 0;
  static bool semihosting_tick_freq_bigger = false;
  static clock_t semihosting_tick_freq_multiplier = 0;
  clock_t elapsed;

  /* SYS_ELAPSED semihosting call returns a single 64-bit value for 64-bit
     targets and two 32-bit values for 32-bit targets.  */
#if __riscv_xlen == 32
  long data_block[2];
#else
  long data_block[1];
#endif

  if (!initialized)
    {
      /* clock() function from libc must return value which gives us seconds
	 when it's multiplied by CLOCKS_PER_SEC. By default, CLOCKS_PER_SEC
	 is 10**6 for RISC-V. However, semihosting's tick frequency may
	 differ and usually it's 10**9. Thus, we have to obtain a real value
	 of the tick frequency for the current semihosting setup and
	 calculate a multiplier and use it for adjusting semihosting's
	 number of ticks. E.g., if semihosting's ticks frequency is 10**9 then
	 multiplier is 10**9 / 10**6 = 1000.  */
      semihosting_tick_freq = syscall_errno (SEMIHOST_tickfreq, NULL);

      if (semihosting_tick_freq > CLOCKS_PER_SEC)
        {
	  semihosting_tick_freq_multiplier = semihosting_tick_freq / CLOCKS_PER_SEC;
	  semihosting_tick_freq_bigger = true;
        }
      else
	semihosting_tick_freq_multiplier = CLOCKS_PER_SEC / semihosting_tick_freq;

      initialized = true;
    }

  /* SYS_ELAPSED semihosting call returns a number of ticks.  */
  syscall_errno (SEMIHOST_elapsed, data_block);

#if __riscv_xlen == 32
  elapsed = (((uint64_t) data_block[1]) << 32) | ((uint32_t) data_block[0]);
#else
  elapsed = data_block[0];
#endif

  /* Adjust the number of ticks to make it compatible with CLOCKS_PER_SEC.  */
  if (semihosting_tick_freq_bigger)
    elapsed /= semihosting_tick_freq_multiplier;
  else
    elapsed *= semihosting_tick_freq_multiplier;

  if (buf)
    {
      buf->tms_utime = elapsed;
      buf->tms_stime = 0;
      buf->tms_cutime = 0;
      buf->tms_cstime = 0;
    }

  return elapsed;
}
