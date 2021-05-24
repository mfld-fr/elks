# Helper to run ELKS in QEMU

# Auto-select QEMU system emulator variant
[ -x /usr/bin/qemu-system-i386 ] && QEMU="qemu-system-i386"
[ -x /usr/bin/qemu-system-x86_64 ] && QEMU="qemu-system-x86_64"
[ -x /usr/local/bin/qemu-system-i386 ] && QEMU="qemu-system-i386"
[ -x /usr/local/bin/qemu-system-x86_64 ] && QEMU="qemu-system-x86_64"
[ -z $QEMU ] && { echo 'QEMU system emulator not found!'; exit 1; }
echo "Using QEMU: $QEMU"

# Select disk image to use
# MINIX or FAT .config build
[ -f image/fd.bin ] && IMAGE="-fda image/fd.bin"
[ -f image/hd.bin ] && IMAGE="-hda image/hd.bin"
[ -z "$IMAGE" ] && { echo 'Disk image not found!'; exit 1; }
echo "Using disk image: $IMAGE"

# Select your keyboard mapping here:
# KEYBOARD="-k en-us"
# KEYBOARD="-k fr"
KEYBOARD=

# Host forwarding for networking
# No forwarding: only outgoing from ELKS to host
# HOSTFWD="-net user"
# Incoming telnet forwarding: example: connect to ELKS with telnet localhost 2323
# HOSTFWD="-net user,hostfwd=tcp:127.0.0.1:2323-10.0.2.15:23"
# Incoming http forwarding: example: connect to ELKS httpd with 'http://localhost:8080'
# HOSTFWD="-net user,hostfwd=tcp:127.0.0.1:8080-10.0.2.15:80"
HOSTFWD="-net user"

# Enable network dump here:
# NETDUMP="-net dump"

# Determine display type ("Darwin" = OSX)
[ `uname` != 'Darwin' ] && QDISPLAY="-display sdl"

# Configure QEMU as pure ISA system

#SERIAL="-chardev pty,id=chardev1 -device isa-serial,chardev=chardev1,id=serial1"

$QEMU -nodefaults -name ELKS -machine isapc -cpu 486,tsc -m 1M \
$KEYBOARD $QDISPLAY -vga std -rtc base=utc $SERIAL \
-net nic,model=ne2k_isa $HOSTFWD $NETDUMP $IMAGE $DISK2 $@
