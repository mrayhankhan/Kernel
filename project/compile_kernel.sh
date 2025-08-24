#!/bin/bash

# Kernel compilation script
cd /workspaces/Kernel/project/linux-6.6

echo "Starting kernel compilation..."
echo "This will take a while (15-30 minutes depending on the system)"

make -j$(nproc)

echo "Kernel compilation completed!"
echo "Compiling and installing modules..."

make modules_install INSTALL_MOD_PATH=../

echo "Creating modules archive..."
cd ..
tar -cvf lib.tar.bz2 lib

echo "=== Compilation Complete ==="
echo "Kernel image: linux-6.6/arch/x86_64/boot/bzImage"
echo "Modules archive: lib.tar.bz2"
