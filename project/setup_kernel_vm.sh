#!/bin/bash

# Custom Linux Kernel Compilation and VM Setup Script
# This script automates the process of building a custom kernel and setting up a VM

set -e  # Exit on any error

PROJECT_DIR="/workspaces/Kernel/project"
KERNEL_VERSION="6.6"  # Using 6.6 as 6.16 doesn't exist yet
UBUNTU_ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04.3-desktop-amd64.iso"
UBUNTU_ISO_NAME="ubuntu-24.04.3-desktop-amd64.iso"
VM_DISK="linux.qcow2"
VM_MEMORY="6G"
VM_DISK_SIZE="20G"

echo "=== Custom Linux Kernel VM Setup ==="
echo "Project directory: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Step 1: Install QEMU
echo "Step 1: Installing QEMU..."
sudo apt update
sudo apt install -y qemu-kvm qemu-system-x86 qemu-utils

# Step 2: Download Ubuntu ISO
echo "Step 2: Downloading Ubuntu ISO..."
if [ ! -f "$UBUNTU_ISO_NAME" ]; then
    echo "Downloading Ubuntu ISO from $UBUNTU_ISO_URL"
    wget "$UBUNTU_ISO_URL" -O "$UBUNTU_ISO_NAME"
else
    echo "Ubuntu ISO already exists, skipping download."
fi

# Step 3: Create VM disk image
echo "Step 3: Creating VM disk image..."
if [ ! -f "$VM_DISK" ]; then
    qemu-img create -f qcow2 "$VM_DISK" "$VM_DISK_SIZE"
else
    echo "VM disk already exists, skipping creation."
fi

# Step 4: Install basic packages for kernel compilation
echo "Step 4: Installing kernel compilation dependencies..."
sudo apt install -y build-essential flex bison libelf-dev libssl-dev libdw-dev gawk \
    bc kmod cpio libncurses5-dev libncurses5 wget openssh-server

# Step 5: Download and extract kernel source
echo "Step 5: Downloading kernel source..."
KERNEL_TAR="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_DIR="linux-${KERNEL_VERSION}"

if [ ! -f "$KERNEL_TAR" ]; then
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/$KERNEL_TAR"
fi

if [ ! -d "$KERNEL_DIR" ]; then
    echo "Extracting kernel source..."
    tar -xf "$KERNEL_TAR"
fi

# Step 6: Configure and compile kernel
echo "Step 6: Configuring and compiling kernel..."
cd "$KERNEL_DIR"

# Copy current kernel config as base
if [ -f "/boot/config-$(uname -r)" ]; then
    cp "/boot/config-$(uname -r)" .config
else
    # Fallback to default config
    make defconfig
fi

# Run localmodconfig to optimize for current hardware
echo "Running localmodconfig (press Enter for all prompts)..."
make localmodconfig

# Disable problematic options
scripts/config --disable SYSTEM_TRUSTED_KEYS
scripts/config --disable SYSTEM_REVOCATION_KEYS
scripts/config --module E1000

# Compile kernel
echo "Compiling kernel (this may take a while)..."
make -j$(nproc)

# Install modules to local directory
echo "Installing kernel modules..."
make modules_install INSTALL_MOD_PATH="$PROJECT_DIR"

cd "$PROJECT_DIR"

# Step 7: Create tar file from lib directory
echo "Step 7: Creating lib.tar.bz2..."
if [ -d "lib" ]; then
    tar -cvf lib.tar.bz2 lib
fi

# Step 8: Enable SSH on host
echo "Step 8: Enabling SSH service..."
sudo systemctl enable ssh
sudo systemctl start ssh

echo "=== Setup Complete ==="
echo "VM disk created: $VM_DISK"
echo "Kernel compiled in: $KERNEL_DIR"
echo "Modules archive: lib.tar.bz2"
echo ""
echo "To install Ubuntu in VM, run:"
echo "qemu-system-x86_64 -enable-kvm -m $VM_MEMORY -cdrom $UBUNTU_ISO_NAME -boot d $VM_DISK"
echo ""
echo "To boot VM after installation:"
echo "qemu-system-x86_64 -enable-kvm -m $VM_MEMORY $VM_DISK"
echo ""
echo "To boot with custom kernel:"
echo "qemu-system-x86_64 -enable-kvm -kernel ./$KERNEL_DIR/arch/x86_64/boot/bzImage -append \"root=/dev/sda2 console=ttyS0 nokaslr\" -m $VM_MEMORY -hda $VM_DISK"
