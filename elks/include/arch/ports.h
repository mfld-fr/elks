/*
 * ELKS I/O port and IRQ mappings
 *
 * PC IRQ default mappings (* = possible conflicting uses)
 *
 *  IRQ	ELKS Device         Config Option           Status
 *  0   Timer                                       Required
 *  1   Keyboard            CONFIG_CONSOLE_DIRECT   Optional
 *  2*  Cascade -> 9 on AT  CONFIG_ETH_WD           Optional on XT, not available on AT
 *  3   Com2 (/dev/ttyS1)   CONFIG_CHAR_DEV_RS      Optional
 *  4   Com1 (/dev/ttyS0)   CONFIG_CHAR_DEV_RS      Optional
 *  5*  Unused
 *  5*  Com3 (/devb/ttyS2)  CONFIG_CHAR_DEV_RS      Optional
 *  5*  HW IDE hard drive   CONFIG_BLK_DEV_HD       Driver doesn't work
 *  6*  Unused
 *  6*  HW floppy drive     CONFIG_BLK_DEV_FD       Driver doesn't compile
 *  7   Unused (LPT)
 *  8   Unused (RTC)
 *  9   NE2K (/dev/eth)     CONFIG_ETH_NE2K         Optional
 * 10   Unused (USB)                                Turned off
 * 11   Unused (Sound)                              Turned off
 * 12   Unused (Mouse)                              Turned off
 * 13   Unused (Math coproc.)                       Turned off
 * 14*  AT HD IDE (/dev/hda) CONFIG_BLK_DEV_HD      Driver doesn't work
 * 15*  AT HD IDE (/dev/hdb) CONFIG_BLK_DEV_HD      Driver doesn't work
 *
 * Edit settings below to change port address or IRQ:
 *   Change I/O port and driver IRQ number to match your hardware
 */

#ifdef CONFIG_CHAR_DEV_RS
//#define CONFIG_FAST_IRQ4             /* COM1 very fast serial driver, no ISIG handling*/
//#define CONFIG_FAST_IRQ3             /* COM2 very fast serial driver, no ISIG handling*/
#endif

/* timer, timer-8254.c*/
#define TIMER_CMDS_PORT 0x43		/* command port */
#define TIMER_DATA_PORT 0x40		/* data port    */
#define TIMER_IRQ	0		/* can't change*/

/* bell, bell-8254.c*/
#define TIMER2_PORT	0x42		/* timer 2 data port for speaker frequency*/
#define SPEAKER_PORT	0x61

/* keyboard, kbd-scancode.c*/
#define KBD_IO		0x60
#define KBD_CTL		0x61
#define KBD_IRQ		1

/* serial, serial.c*/
#define COM1_PORT	0x3f8
#define COM1_IRQ	4		/* unregistered unless COM1_PORT found*/

#define COM2_PORT	0x2f8
#define COM2_IRQ	3		/* unregistered unless COM2_PORT found*/

#define COM3_PORT	0x3e8
#define COM3_IRQ	5		/* unregistered unless COM3_PORT found*/

#define COM4_PORT	0x2e8
#define COM4_IRQ	2		/* unregistered unless COM4_PORT found*/

/* ne2k, ne2k.c */
//#define NE2K_IRQ	9
#define NE2K_IRQ	12
#define NE2K_PORT	0x300

/* wd, wd.c*/
#define WD_IRQ		2
#define WD_PORT		0x240

/* obsolete - experimental IDE hard drive, directhd.c (broken)*/
#define HD1_PORT	0x1f0
#define HD2_PORT	0x170
#define HD_IRQ		5		/* missing request_irq call*/
#define HD1_AT_IRQ	14		/* missing request_irq call*/
#define HD2_AT_IRQ	15		/* missing request_irq call*/

/* obsolete - experimental floppy drive, floppy.c (won't compile)*/
#define FLOPPY_IRQ	6		/* missing request_irq call*/