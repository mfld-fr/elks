#include <linuxmt/config.h>
#include <linuxmt/init.h>
#include <linuxmt/mm.h>
#include <linuxmt/sched.h>
#include <linuxmt/types.h>
#include <linuxmt/utsname.h>

#include <arch/system.h>

/*
 *	System variable setups
 */
#ifdef CONFIG_FS_RO
int root_mountflags = MS_RDONLY;
#else
int root_mountflags = 0;
#endif

static void init_task(void);
extern int run_init_process(char *);

/*
 *	For the moment this routine _MUST_ come first.
 */

void start_kernel(void)
{
    seg_t base, end;

/* We set the idle task as #0, and init_task() will be task #1 */

    sched_init();	/* This block of functions don't need console */
    setup_arch(&base, &end);
    mm_init(base, end);
    buffer_init();
    inode_init();
    init_IRQ();
    tty_init();

    init_console();

    device_setup();

#ifdef CONFIG_SOCKET
    sock_init();
#endif

    fs_init();

    mm_stat(base, end);
    printk("ELKS version %s\n", system_utsname.release);

    kfork_proc(init_task);
    wake_up_process(&task[1]);

    /*
     * We are now the idle task. We won't run unless no other process can run.
     */
    while (1) {
        schedule();

#ifdef CONFIG_IDLE_HALT
        idle_halt ();
#endif
    }
}

static void init_task()
{
    int num;

    mount_root();
#ifndef CONFIG_SMALL_KERNEL
    printk("Loading init\n");
#endif

    /* The Linux kernel traditionally attempts to start init from 4 locations,
     * as indicated by this code:
     *
     * run_init_process("/sbin/init");
     * run_init_process("/etc/init");
     * run_init_process("/bin/init");
     * run_init_process("/bin/sh");
     *
     * So, I've modified the ELKS kernel to follow this tradition.
     */

//	run_init_process("/sbin/init");
//	run_init_process("/etc/init");
	run_init_process("/bin/init");

#ifdef CONFIG_CONSOLE_SERIAL
    num = sys_open("/dev/ttyS0", 2, 0);		/* These are for stdin */
#else
    num = sys_open("/dev/tty1", 2, 0);
#endif
    if (num < 0)
	printk("Unable to open /dev/tty1 (error %u)\n", -num);

    if (sys_dup(num) != 1)			/* This is for stdout */
	printk("dup failed\n");
    sys_dup(num);				/* This is for stderr */
    printk("No init - running /bin/sh\n");

    run_init_process("/bin/sh");
    panic("No init or sh found");
}
