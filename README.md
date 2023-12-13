# Hello World OS

This script (`script.sh`) automates the process of building a minimal "Hello World" operating system using the Linux kernel and BusyBox. The resulting OS is launched in a QEMU virtual machine and can also be converted into a bootable ISO for both EFI and Legacy BIOS systems. There is no user/session management or prompt after the system boots. It just prints "hello world".

The script is designed to not require any user input apart from the sudo password to install required dependencies. Also, all files that are needed are downloaded under the working directory.

## Prerequisites
- Tested on Ubuntu 22.04.3 VM
- Internet connection
- Super-user privileges (`sudo`)

## How to Execute

- Clone this repository
- Navigate to the root of the repository
- Run the `script.sh`:
```bash
bash script.sh
```

### Use of Makefile
You can use the Makefile to:

- Execute the `script.sh`
```bash
make run
```
- Delete all downloaded files and folders
```bash
make clean
```

## Steps

### 1. Install Dependencies
- Update package lists and install necessary dependencies using `apt`
- Required packages include `fakeroot`, `build-essential`, `ncurses-dev`, `xz-utils`, `libssl-dev`, `bc`, `flex`, `libelf-dev`, `bison`, `curl`, `qemu-system-x86`, `xorriso`, and `mtools`

### 2. Set up File/Folder Structure
- Create directories for `initrd/proc`, `initrd/sys`, `initrd/dev`, `kernel`, and `busybox`

### 3. Download and Build Linux Kernel
- Download the latest 5.x Linux Kernel (linux-5.15.142)
- Verify the GPG signatures.
- Extract and build the Linux Kernel with multiple jobs for faster compilation

### 4. Download and Build BusyBox
- Download and verify BusyBox source code
- Build BusyBox with static linking for a standalone executable

### 5. Create initrd (Initial RAM Disk)
- Create a basic `init` script
- Mount essential filesystems (devtmpfs, proc, sys)
- Package the initrd using `cpio` and compress it

### 6. Create Bootable ISO
- Check if the system is EFI or Legacy BIOS
- Create a compatible ISO with GRUB

### 7. Launch QEMU
- Launch QEMU with the compiled Linux Kernel and initrd

## Useful Sources
- [Kernel Documentation](https://docs.kernel.org/)
- [Linux Kernel Downloads](https://kernel.org/)
- [BusyBox FAQ](https://busybox.net/FAQ.html)
- [Compiling the Linux Kernel and Creating a Bootable ISO](https://medium.com/@ThyCrow/compiling-the-linux-kernel-and-creating-a-bootable-iso-from-it-6afb8d23ba22)
- [CMK-Linux GitHub Repository](https://github.com/maksimKorzh/cmk-linux/blob/8068de3d7ec713c00c7df0442e8d2dad18ade6cc/tutorials/busybox/initrd.md)
- [Creating a Minimal Linux System](https://gist.github.com/ncmiller/d61348b27cb17debd2a6c20966409e86)