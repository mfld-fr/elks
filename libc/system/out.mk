include $(TOPDIR)/libc/Makefile.inc

CFLAGS	+= -DL_execlp

ifneq "$(VPATH)" ""
	dir	= $(VPATH)/
else
	dir	=
endif

OBJS = \
	abort.o \
	cleanup.o \
	dirent.o \
	dup.o \
	dup2.o \
	environ.o \
	errno.o \
	execl.o \
	execle.o \
	execlp.o \
	execv.o \
	execve.o \
	execvp.o \
	getegid.o \
	geteuid.o \
	getgid.o \
	getpgid.o \
	getpid.o \
	getppid.o \
	getuid.o \
	killpg.o \
	lseek.o \
	mkfifo.o \
	setjmp.o \
	setpgrp.o \
	signal.o \
	sleep.o \
	syscall0.o \
	time.o \
	times.o \
	usleep.o \
	wait.o \
	wait3.o \
	waitpid.o \

include syscall.mk

all: out.a

out.a: $(OBJS)
	$(RM) $@
	$(AR) $(ARFLAGS_SUB) $@ $^

clean::
	$(RM) $(OBJS)
