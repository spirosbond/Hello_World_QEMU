#!/bin/bash
# Tested on Ubuntu 22.04.3 VM
# Requirements: Internet connection, super-user privileges

echo "Start..."

# Store the current working directory in a variable
home_dir=$PWD

# Update package lists and install necessary dependencies
echo "Installing dependencies..."
sudo apt update
sudo apt install -y fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison curl qemu-system-x86 xorriso mtools

# Set up file structure
echo "Creating folder structure..."
mkdir -p initrd/proc initrd/sys initrd/dev kernel busybox

# Download the latest 5.x Linux Kernel
echo "Downloading Linux Kernel..."
cd kernel
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.142.tar.xz
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.142.tar.sign

# Verify the GPG signatures
echo "Verifying Linux Kernel..."
gpg --locate-keys torvalds@kernel.org gregkh@kernel.org
unxz linux-5.15.142.tar.xz
gpg --verify linux-5.15.142.tar.sign
tar -xf linux-5.15.142.tar

echo "Building Linux Kernel (64-bit)..."
cd linux-5.15.142
make x86_64_defconfig
make -j $(nproc)  # Build the Linux Kernel with multiple jobs for faster compilation

# Download and build BusyBox
echo "Downloading Busybox..."
cd $home_dir/busybox
wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2.sig
echo "Verifying Busybox..."
curl -sSL http://busybox.net/~vda/vda_pubkey.gpg | gpg --import -
gpg --verify busybox-1.36.1.tar.bz2.sig
tar -xf busybox-1.36.1.tar.bz2

echo "Building Busybox..."
cd busybox-1.36.1/
make defconfig
LDFLAGS="--static" make -j $(nproc)  # Build BusyBox with static linking for a standalone executable
LDFLAGS="--static" make CONFIG_PREFIX=$PWD/build install

# Create initrd
echo "Creating Init RAM Disk..."
cd $home_dir/initrd
touch init
printf "%s\n" '#!/bin/sh' "mount -t devtmpfs none /dev" "mount -t proc none /proc" "mount -t sysfs none /sys" 'echo "hello world"' "sleep 99999999" > init
chmod +x init
cp -a $home_dir/busybox/busybox-1.36.1/build/. .
find . | cpio -o -H newc | gzip > root.cpio.gz

# Create bootable ISO
echo "Creating bootable iso..."
cd $home_dir
if [[ -d /sys/firmware/efi ]]; then
    echo 'EFI system'
    mkdir -p efi_iso/boot/grub
    cp -a kernel/linux-5.15.142/arch/x86/boot/bzImage efi_iso/boot/
    cp -a initrd/root.cpio.gz efi_iso/boot/
    touch efi_iso/boot/grub/grub.cfg
    printf "%s\n" \
    "set default=0" \
    "set timeout=10" \
    "insmod efi_gop" \
    "insmod font" \
    "if loadfont /boot/grub/fonts/unicode.pf2" \
    "then" \
    "   insmod gfxterm" \
    "   set gfxmode=auto" \
    "   set gfxpayload=keep" \
    "   terminal_output gfxterm" \
    "fi" \
    "menuentry 'hello_world_os' --class os {" \
    "   insmod gzio" \
    "   insmod part_msdos" \
    "   linux /boot/bzImage" \
    "   initrd /boot/root.cpio.gz" \
    "}" \
    > efi_iso/boot/grub/grub.cfg
    grub-mkrescue -o hello_world_os_efi.iso efi_iso/
else
    echo 'Legacy BIOS system'
    mkdir -p grub_iso/boot/grub
    cp -a kernel/linux-5.15.142/arch/x86/boot/bzImage grub_iso/boot/
    cp -a initrd/root.cpio.gz grub_iso/boot/
    touch grub_iso/boot/grub/grub.cfg
    printf "%s\n" \
    "set default=0" \
    "set timeout=10" \
    "menuentry 'hello_world_os' --class os {" \
    "   insmod gzio" \
    "   insmod part_msdos" \
    "   linux /boot/bzImage" \
    "   initrd /boot/root.cpio.gz" \
    "}" \
    > grub_iso/boot/grub/grub.cfg
    grub-mkrescue -o hello_world_os_legacy.iso grub_iso/
fi

# Launch QEMU
cd $home_dir
echo "Running image in qemu..."
qemu-system-x86_64 -no-reboot -kernel kernel/linux-5.15.142/arch/x86_64/boot/bzImage -initrd initrd/root.cpio.gz

:<<COMMENT
Useful Sources:
https://docs.kernel.org/
https://kernel.org/
https://busybox.net/FAQ.html
https://medium.com/@ThyCrow/compiling-the-linux-kernel-and-creating-a-bootable-iso-from-it-6afb8d23ba22
https://github.com/maksimKorzh/cmk-linux/blob/8068de3d7ec713c00c7df0442e8d2dad18ade6cc/tutorials/busybox/initrd.md
https://gist.github.com/ncmiller/d61348b27cb17debd2a6c20966409e86

COMMENT