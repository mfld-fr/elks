//------------------------------------------------------------------------------
// ELKS boot sector
//------------------------------------------------------------------------------

// If BOOT_FAT is undefined, this assembles to a filesystem-independent boot
// sector which loads a stage 2 bootloader on the second disk sector
//
// If BOOT_FAT is defined, this assembles to a single-sector bootloader that
// reads and runs /linux on a FAT12/FAT16 filesystem

#include <autoconf.h>

#include "boot_err.h"

#define BOOTADDR  0x7C00
#define LOADSEG   0x1000

// Must match ELKS
#define ELKS_INITSEG (0x0100)
#define ELKS_SYSSEG  (0x1000)

	.code16

	.text

// Loaded by the BIOS at 0:7C00h (32K - 1K) with DL = boot drive number

entry:

// Allow the new BIOS floppy parameter table to clobber the first few bytes
// of the boot sector after we are done with them

floppy_table:

#ifdef BOOT_FAT
	jmp entry1
	.org 3, 0x90

#include "boot_sect_fat.h"

	FAT_BPB

entry1:
#endif

	// Get the memory size
	// TODO: optional BIOS INT 12h

	int $0x12   // in KB
	mov $6,%cl  // to paragraphs
	shl %cl,%ax

	// Move to the highest & aligned 64K

	// Some BIOSes are intolerant to unaligned buffer for INT 13h
	// so the 64K is the safest possible alignement in all cases

	sub $0x1000,%ax
	and $0xF000,%ax
	mov %ax,%es

	xor %di,%di
	mov %di,%ds
	mov $BOOTADDR,%si
	mov $256,%cx  // 256 words = 512 B
	cld
	rep
	movsw

	// Copy the current BIOS floppy parameter table
	// so that we could modify it locally

	mov $0x78,%bx  // 0:78h (INT vector 1Eh)
	lds (%bx),%si  // ds:si = BIOS original table
.if floppy_table == entry
	xor %di,%di
.else
	mov $floppy_table,%di
.endif
	push %di
	mov $6,%cl     // 12 bytes (actually 11 in the table) and CH = 0
	//cld
	rep
	movsw

	// Change BIOS table pointer to our copy

	mov %cx,%ds    // CX = 0
	popw (%bx)
	mov %es,2(%bx)

	// Rebase CS DS ES SS to work in the 64K segment

	push %es
	pop %ds
	push %es
	pop %ss        // automatic CLI for next instruction
	xor %sp,%sp

	push %ss
	mov $_next1,%cl  // CH = 0
	push %cx
	retf

_next1:

	// Save boot drive as provided by BIOS

	mov %dl,drive_num  // DX preserved above

	// Print header

	mov $msg_boot,%bx
	call _puts

	// Set sector count in floppy parameter table

	mov sect_max,%al
	mov %al,floppy_table + 4

#ifndef BOOT_FAT
	// Load the second sector of the boot block

	mov $1,%ax
	mov %ax,%dx
	mov $payload,%cx
	push %ss
	mov $ERR_PAYLOAD,%bl
	call _disk_read

	call payload
#else
	// Load the file /linux from the FAT12/16 filesystem's root directory

	FAT_LOAD_AND_RUN_KERNEL
#endif

no_system:
	mov $ERR_NO_SYSTEM,%al
	// fall through to _except

//------------------------------------------------------------------------------

// We use an exception-like basic mechanism
// to save the space required by error returning

// void except (char code)

	.global except

except:
_except:
	// AL = exception code
	xor %sp,%sp
	add $'0',%al  // first version with single digit
	call _putc
	mov $msg_error,%bx
	jmp _reboot1

	.global _reboot

_reboot:

	mov $msg_reboot,%bx

_reboot1:
	call _puts

	xor %ax,%ax  // wait for key
	int $0x16

	int $0x19    // BIOS bootstrap
	jmp _reboot

//------------------------------------------------------------------------------

	.global _putc

_putc:

	mov $7,%bx    // page 0 - color 7
	mov $0xE,%ah  // teletype write
	int $0x10     // BIOS video services
	ret

	.global puts

puts:
	xchg %ax,%bx
	// fall through

	.global _puts

_puts:

	mov (%bx),%al
	or %al,%al
	jz 1f
	push %bx
	call _putc
	pop %bx
	inc %bx
	jmp _puts
1:  ret

//------------------------------------------------------------------------------

// int drive_reset (int drive)
/*
	.global drive_reset

drive_reset:
	mov %sp,%bx
	mov 2(%bx),%dx  // DL = drive (0 based)
	xor %ah,%ah
	int $0x13
	mov %ah,%al     // AH = status
	xor %ah,%ah
	ret
*/

//------------------------------------------------------------------------------

// void disk_read (int sect, int count, byte_t * buf, int seg)

#ifdef BOOT_FAT
_disk_read_at_bx_0:
	// Load sectors at the absolute address BX:0 --- used by FAT loader
	pop %cx
	push %bx
	push %cx
	xor %cx,%cx
	// fall through
#endif

	.global disk_read

disk_read:
	// AX = sect
	// DX = count
	// CX = buf
	// seg pushed on stack
	mov $ERR_DISK_READ,%bl

_disk_read:
	// BL = error code in case of failure

	mov $5,%bh
	push %bp
	mov %sp,%bp
	push %ax
	push %dx
	push %cx
	push %bx

// word 4(%bp) = segment
// word -2(%bp) = logical sector number
// word -4(%bp) = logical count
// word -6(%bp) = buffer offset
// byte -7(%bp) = no. of retries left
// byte -8(%bp) = failure error code

dr_loop:
	// Compute the CHS from logical sector
	// AX = logical sector
	mov sect_max,%bl
	xor %bh,%bh
	xor %dx,%dx
	divw %bx
	mov %dl,%cl      // CL = physical sector number in track, minus 1
	divb head_max
	mov %al,%ch      // CH = physical cylinder number
	xchg %ax,%dx     // DH = physical head number

	// Compute number of sectors to read
	// First limit the sector count to the end of the track

	sub %cl,%bl
	inc %cx          // base 1 for sector number
	mov -4(%bp),%ax
	cmp %bx,%ax
	jna dr_over
	xchg %ax,%bx

	// Also make sure the read does not overshoot the end of ES
	//
	// And, make sure we do not read more than 0x7F sectors at one go
	// (this slightly simplifies the advance-in-buffer calculations
	// later on)

	mov -6+1(%bp),%bl
	neg %bl
	shr %bl
	jnz dr_over
	mov $0x7F,%bl
dr_over:
	cmp %bl,%al      // BL ranges from 1 to 0x7F inclusive
	jna dr_over2
	xchg %ax,%bx     // AL = number of sectors to read for this round

dr_over2:
	mov drive_num,%dl

dr_try:
	push %ax
	push %cx
	push %dx
	push %es
	mov -6(%bp),%bx
	mov 4(%bp),%es
	mov $0x02,%ah    // BIOS read disk
	int $0x13
	pop %es

	jnc dr_cont

	xor %ah,%ah
	int $0x13

	// PATCH: failure trace

	mov $'*',%al
	call _putc

	decb -7(%bp)
	pop %dx
	pop %cx
	pop %ax
	mov $1,%al       // if retry needed, try reading just _one_ sector...
	jnz dr_try

	// TODO: use BIOS returned error
	pop %ax
	jmp _except

dr_cont:
	// Reset retry count

	movb $5,-7(%bp)

	// PATCH: success trace

	mov $'.',%al
	call _putc

	pop %dx
	pop %cx
	pop %ax

	// Update logical sector number and logical count
	// AL = number of sectors just read, which is at most 0x7F

	cbtw
	sub %ax,-4(%bp)
	jz dr_exit
	add %ax,-2(%bp)

	// Advance in buffer; advance BX, then advance ES if BX overflows

	shl %al          // cannot overflow :-)
	add %al,-6+1(%bp)
	jnc dr_next
	addb $0x10,4+1(%bp)

dr_next:
	mov -2(%bp),%ax
	jmp dr_loop

dr_exit:
	mov %bp,%sp
	pop %bp
	ret $2

//------------------------------------------------------------------------------

#ifndef BOOT_FAT
// void run_prog ()

	.global run_prog

// TODO: to be moved to the MINIX specific payload

run_prog:

/*
static
run_prog()
{
// It all worked, run the loaded executable
#asm
#ifdef HARDDISK
  mov	dx,[bootpart+2]
  xchg	dh,dl		! DX => hard drive
  push	[bootpart]	! CX => partition offset
  xor	si,si
#else
  xor	dx,dx		! DX=0 => floppy drive
  push	dx		! CX=0 => partition offset = 0
  mov	si,[_n_sectors]	! Save for monitor.out
#endif

  mov	bx,#LOADSEG
  mov	ds,bx		! DS = loadaddress
  xor	di,di		! Zero
  mov	ax,[di]
  cmp	ax,#0x0301	! Right magic ?
  jnz	binfile		! Yuk ... assume .SYS
  inc	bx
  inc	bx		! bx = initial CS
  mov	ax,[di+2]
  and	ax,#$20		! Is it split I/D ?
  jz	impure		! No ...
  mov	cl,#4
  mov	ax,[di+8]
  shr	ax,cl
impure:
  pop	cx
  add	ax,bx
  mov	ss,ax
  mov	sp,[di+24]	! Chmem value
  mov	ds,ax
binfile:

  push	bx
  push	di		!  jmpi	0,#LOADSEG+2
  retf
#endasm
}
*/

	push %ds
	mov $LOADSEG,%ax
	mov %ax,%ds

	mov 0x01E6,%ax  // check for ELKS magic number
	cmp $0x4C45,%ax
	jnz not_elks
	mov 0x01E8,%ax
	cmp $0x534B,%ax
	jz  boot_it

not_elks:

	pop %ds
	mov $ERR_BAD_SYSTEM,%al
	jmp _except

boot_it:

	pop %ax
	mov $ELKS_INITSEG,%ax
	mov %ax,%es

	mov 497,%bl  // fetch number of setup sectors
	xor %bh,%bh
	inc %bx
	mov 500,%ax  // fetch system executable size
	mov $5,%cl
	add $31,%ax
	shr %cl,%ax
	mov %ax,%dx

// Put the setup where it belongs

looping:
	call copy_sect
	dec %bx
	jnz looping

	mov	$ELKS_SYSSEG,%ax
	mov %ax,%es

// Put the system code at the right place

looping2:
	call copy_sect
	dec %dx
	jnz looping2

// Ok, everything should be where it belongs call it

	mov $ELKS_INITSEG,%ax
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%ss
	mov $0x4000-12,%sp
	ljmp $ELKS_INITSEG+0x20,$0

copy_sect:
	mov $256,%cx
	xor %si,%si
	xor %di,%di
	rep
	movsw

	mov %ds,%ax
	add $32,%ax
	mov %ax,%ds
	mov %es,%ax
	add $32,%ax
	mov %ax,%es
	ret
#endif

//------------------------------------------------------------------------------

msg_boot:
	.asciz "ELKS"

msg_error:
	.ascii "!\r\n"
	// fall through

msg_reboot:
	.asciz "Press key\r\n"

	.global last_code
last_code:
//------------------------------------------------------------------------------

// ELKS disk parameter structure
// For future expansion, fields should be added at the _front_ of structure

	.org 0x1F7

elks_parms_start:

// Disk geometry (CHS)

	.global sect_max
	.global head_max
	.global track_max

// TODO: number of tracks is not used

track_max:
#   if defined(CONFIG_IMG_FD360)
	.word 40
#   elif defined(CONFIG_IMG_FD720) || defined(CONFIG_IMG_FD1440)
	.word 80
#   elif defined(CONFIG_IMG_HD)
	.word CONFIG_IMG_CYL
#   else
	.warning "Unknown number of disk tracks!"
	.word 0
#   endif

#   ifndef BOOT_FAT
sect_max:
#   endif
#   if defined(CONFIG_IMG_FD360) || defined(CONFIG_IMG_FD720)
	.byte 9
#   elif defined(CONFIG_IMG_FD1200)
	.byte 15
#   elif defined(CONFIG_IMG_FD1440)
	.byte 18
#   elif defined(CONFIG_IMG_FD1680)
	.byte 21
#   elif defined(CONFIG_IMG_HD)
	.byte CONFIG_IMG_SECT
#   else
	.warning "Unknown number of disk sectors per track!"
	.byte 0
#   endif

#   ifndef BOOT_FAT
head_max:
#   endif
#   if defined(CONFIG_IMG_FD360) || defined(CONFIG_IMG_FD720) \
       || defined(CONFIG_IMG_FD1200) || defined(CONFIG_IMG_FD1440) \
       || defined(CONFIG_IMG_FD1680)
	.byte 2
#   elif defined(CONFIG_IMG_HD)
	.byte CONFIG_IMG_HEAD
#   else
	.warning "Unknown number of disk sides/heads!"
	.byte 0
#   endif

// Marker to indicate presence and size of ELKS parameter structure

	.byte . - elks_parms_start
	.ascii "eL"
	.org 0x1FE

//------------------------------------------------------------------------------

// Boot drive as provided by BIOS on entry
// Allow this variable to overlap the "eL" marker (above)

	.global drive_num

	.set drive_num, . - 1

// Magic at end of first sector
// to mark it as bootable for BIOS

	.word 0xAA55

#ifndef BOOT_FAT
// Here comes the first sector of the payload
// that is specific to the filesystem

	.org 0x200

payload:
#endif

//------------------------------------------------------------------------------
