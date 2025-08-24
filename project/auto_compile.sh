#!/bin/bash

# Automated kernel compilation with proper configuration
cd /workspaces/Kernel/project/linux-6.6

echo "Configuring kernel automatically..."

# Set up proper configuration non-interactively
make olddefconfig

# Ensure the problematic options are disabled
scripts/config --disable SYSTEM_TRUSTED_KEYS
scripts/config --disable SYSTEM_REVOCATION_KEYS
scripts/config --module E1000

# Regenerate config
make olddefconfig

echo "Starting kernel compilation..."
echo "This will take a while (15-30 minutes depending on the system)"

# Start compilation
make -j$(nproc)

echo "Kernel compilation completed!"
echo "Installing modules locally..."

make modules_install INSTALL_MOD_PATH=../

echo "Creating modules archive..."
cd ..
tar -czf lib.tar.bz2 lib

echo "=== Compilation Complete ==="
echo "Kernel image: linux-6.6/arch/x86_64/boot/bzImage"
echo "Modules archive: lib.tar.bz2"
echo "VM disk: linux.qcow2"

ls -la
