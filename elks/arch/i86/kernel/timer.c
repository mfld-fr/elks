#include <linuxmt/config.h>
#include <linuxmt/mm.h>
#include <linuxmt/timer.h>
#include <linuxmt/timex.h>

#include <arch/io.h>
#include <arch/irq.h>
#include <arch/ports.h>

/*
 *	Timer tick routine
 *
 * 9/1999 The 100 Hz system timer 0 can configure for variable input
 *        frequency. Christian Mardm"oller (chm@kdt.de)
 */

volatile jiff_t jiffies = 0;


void timer_tick(int irq, struct pt_regs *regs)
{
    do_timer(regs);
}
