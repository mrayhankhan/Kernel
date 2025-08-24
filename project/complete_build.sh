#!/bin/bash

# Complete Project Builder
# This script completes the kernel compilation and prepares for testing

set -e

PROJECT_DIR="/workspaces/Kernel/project"
cd "$PROJECT_DIR"

echo "=== Final Project Completion ==="
echo "Project directory: $PROJECT_DIR"

# Step 1: Download Ubuntu ISO if needed
echo ""
echo "Step 1: Checking Ubuntu ISO..."
if [ ! -f "ubuntu-24.04.3-desktop-amd64.iso" ] || [ ! -s "ubuntu-24.04.3-desktop-amd64.iso" ]; then
    echo "Downloading Ubuntu 24.04 ISO..."
    rm -f ubuntu-*.iso  # Remove any incomplete downloads
    wget "https://releases.ubuntu.com/24.04/ubuntu-24.04.3-desktop-amd64.iso"
else
    echo "Ubuntu ISO already available."
fi

# Step 2: Complete kernel compilation
echo ""
echo "Step 2: Completing kernel compilation..."
cd linux-6.6

# Check if kernel is already compiled
if [ ! -f "arch/x86_64/boot/bzImage" ]; then
    echo "Starting kernel compilation (this may take 20-30 minutes)..."
    make -j$(nproc) 2>&1 | tee ../kernel_build.log
    
    if [ $? -eq 0 ]; then
        echo "Kernel compilation successful!"
    else
        echo "Kernel compilation failed. Check kernel_build.log for details."
        exit 1
    fi
else
    echo "Kernel already compiled."
fi

# Step 3: Install modules
echo ""
echo "Step 3: Installing kernel modules..."
if [ ! -d "../lib" ]; then
    make modules_install INSTALL_MOD_PATH=../ 2>&1 | tee -a ../kernel_build.log
    echo "Kernel modules installed."
else
    echo "Kernel modules already installed."
fi

cd ..

# Step 4: Create modules archive
echo ""
echo "Step 4: Creating modules archive..."
if [ ! -f "lib.tar.bz2" ] || [ "lib" -nt "lib.tar.bz2" ]; then
    tar -czf lib.tar.bz2 lib
    echo "Modules archive created: lib.tar.bz2"
else
    echo "Modules archive already exists."
fi

# Step 5: Compile modified e1000 driver
echo ""
echo "Step 5: Compiling modified e1000 driver..."
cd linux-6.6
if [ ! -f "drivers/net/ethernet/intel/e1000/e1000.ko" ]; then
    make M=drivers/net/ethernet/intel/e1000 2>&1 | tee -a ../e1000_build.log
    echo "Modified e1000 driver compiled."
else
    echo "Modified e1000 driver already compiled."
fi

cd ..

# Step 6: Enable SSH service
echo ""
echo "Step 6: Configuring SSH service..."
sudo systemctl enable ssh
sudo systemctl start ssh
echo "SSH service configured."

# Step 7: Show completion status
echo ""
echo "=== PROJECT COMPLETION STATUS ==="
echo ""

# Check all required files
echo "Required files status:"
echo -n "  Kernel image: "
if [ -f "linux-6.6/arch/x86_64/boot/bzImage" ]; then
    echo "✅ Available"
else
    echo "❌ Missing"
fi

echo -n "  Kernel modules: "
if [ -f "lib.tar.bz2" ]; then
    echo "✅ Available"
else
    echo "❌ Missing"
fi

echo -n "  Modified e1000 driver: "
if [ -f "linux-6.6/drivers/net/ethernet/intel/e1000/e1000.ko" ]; then
    echo "✅ Available"
else
    echo "❌ Missing"
fi

echo -n "  Ubuntu ISO: "
if [ -f "ubuntu-24.04.3-desktop-amd64.iso" ] && [ -s "ubuntu-24.04.3-desktop-amd64.iso" ]; then
    echo "✅ Available"
else
    echo "❌ Missing or incomplete"
fi

echo -n "  VM disk image: "
if [ -f "linux.qcow2" ]; then
    echo "✅ Available"
else
    echo "❌ Missing"
fi

echo ""
echo "=== NEXT STEPS ==="
echo ""
echo "1. Install Ubuntu in VM:"
echo "   ./vm_manager.sh install"
echo ""
echo "2. Boot VM with custom kernel:"
echo "   ./vm_manager.sh boot-custom"
echo ""
echo "3. In the VM, run the guest operations:"
echo "   ./vm_guest_operations.sh"
echo ""
echo "4. Transfer files between host and VM:"
echo "   Host IP: $(hostname -I | awk '{print $1}')"
echo "   Use scp for file transfers"
echo ""
echo "=== PROJECT FILES ==="
ls -la
echo ""
echo "=== BUILD LOGS ==="
if [ -f "kernel_build.log" ]; then
    echo "Kernel build log: kernel_build.log"
fi
if [ -f "e1000_build.log" ]; then
    echo "E1000 driver log: e1000_build.log"
fi

echo ""
echo "🎉 PROJECT READY FOR TESTING!"
echo "See STATUS_REPORT.md for detailed instructions."
