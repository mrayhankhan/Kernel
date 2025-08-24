#!/bin/bash

# Quick setup for kernel compilation project
# This script downloads and sets up the basic files needed

set -e

PROJECT_DIR="/workspaces/Kernel/project"
cd "$PROJECT_DIR"

echo "=== Quick Kernel Setup ==="

# Step 1: Create VM disk
echo "Creating VM disk image..."
qemu-img create -f qcow2 linux.qcow2 20G

# Step 2: Download kernel source
echo "Downloading kernel 6.6 source..."
KERNEL_VERSION="6.6"
KERNEL_TAR="linux-${KERNEL_VERSION}.tar.xz"

if [ ! -f "$KERNEL_TAR" ]; then
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/$KERNEL_TAR"
fi

# Step 3: Extract kernel
if [ ! -d "linux-${KERNEL_VERSION}" ]; then
    echo "Extracting kernel source..."
    tar -xf "$KERNEL_TAR"
fi

# Step 4: Basic configuration
cd "linux-${KERNEL_VERSION}"

echo "Configuring kernel..."
make defconfig

# Enable modules and disable problematic options
scripts/config --enable MODULES
scripts/config --enable MODULE_UNLOAD
scripts/config --module E1000
scripts/config --disable SYSTEM_TRUSTED_KEYS
scripts/config --disable SYSTEM_REVOCATION_KEYS

echo "=== Basic setup complete ==="
echo "Next: Compile kernel with 'make -j\$(nproc)'"
echo "From directory: $PROJECT_DIR/linux-${KERNEL_VERSION}"
