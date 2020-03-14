/* File: arch/i86/include/arch/types.h */
/* this is the actual "asm/types.h" in user land */

#pragma once

/* Portable types */

#include <stdint.h>

/* Shorter than C99 */

typedef uint8_t  u8_t;
typedef uint16_t u16_t;
typedef uint32_t u32_t;

typedef int8_t  s8_t;
typedef int16_t s16_t;
typedef int32_t s32_t;

/* Linux traditional short types */

typedef uint8_t  __u8;
typedef uint16_t __u16;
typedef uint32_t __u32;

typedef int8_t   __s8;
typedef int16_t  __s16;
typedef int32_t  __s32;

/* 8086 types */

typedef  u8_t byte_t;
typedef u16_t word_t;
typedef u16_t seg_t;
typedef u32_t addr_t;

/* Optimal boolean size for IA16 is word_t */

typedef word_t bool_t;

/* Then we define registers, etc... */

struct _registers {
    __u16	ax, bx, cx, dx, di, si,
		es, ds, sp, ss;
};

typedef struct _registers		__registers,	*__pregisters;

struct xregs {
    __u16	cs, ksp;
};

struct pt_regs {
    __u16	ax, bx, cx, dx, di, si,
		es, ds, sp, ss;
};

/* Changed to unsigned short int as that is what it is here.
 */

typedef __u16			__pptr;

/*@+namechecks@*/

#ifndef NULL
#define NULL		((void *) 0)
#endif

