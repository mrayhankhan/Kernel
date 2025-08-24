#!/bin/bash

# QUICK START GUIDE - Custom Linux Kernel Project
# Run this script to get started immediately

set -e

echo "🚀 CUSTOM LINUX KERNEL PROJECT - QUICK START"
echo "=============================================="
echo ""

# Check if we're in the right directory
if [ ! -f "quick_setup.sh" ]; then
    echo "❌ Error: Please run this script from the project directory"
    echo "   cd /workspaces/Kernel/project"
    echo "   ./QUICK_START.sh"
    exit 1
fi

echo "📍 Current directory: $(pwd)"
echo ""

# Step 1: Check dependencies
echo "Step 1: Checking system dependencies..."
echo "----------------------------------------"

MISSING_DEPS=""

# Check for essential commands
for cmd in qemu-system-x86_64 make gcc wget tar; do
    if ! command -v $cmd >/dev/null 2>&1; then
        MISSING_DEPS="$MISSING_DEPS $cmd"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    echo "❌ Missing dependencies:$MISSING_DEPS"
    echo ""
    echo "📦 Installing required packages..."
    sudo apt update
    sudo apt install -y qemu-system-x86 qemu-utils build-essential flex bison \
                        libelf-dev libssl-dev libdw-dev gawk bc kmod cpio \
                        libncurses-dev wget openssh-server
    echo "✅ Dependencies installed!"
else
    echo "✅ All dependencies found!"
fi

echo ""

# Step 2: Make scripts executable
echo "Step 2: Setting up scripts..."
echo "-----------------------------"
chmod +x *.sh
echo "✅ Scripts made executable"

echo ""

# Step 3: Show current status
echo "Step 3: Project status check..."
echo "-------------------------------"

echo "Files present:"
echo -n "  Kernel source: "
if [ -d "linux-6.6" ]; then
    echo "✅ Available"
else
    echo "❌ Missing (will be downloaded)"
fi

echo -n "  VM disk: "
if [ -f "linux.qcow2" ] && [ -s "linux.qcow2" ]; then
    echo "✅ Available"
else
    echo "❌ Missing (will be created)"
fi

echo -n "  Ubuntu ISO: "
if [ -f "ubuntu-24.04.3-desktop-amd64.iso" ] && [ -s "ubuntu-24.04.3-desktop-amd64.iso" ]; then
    echo "✅ Available"
else
    echo "❌ Missing (will be downloaded)"
fi

echo ""

# Step 4: Show next steps
echo "🎯 NEXT STEPS - Choose your path:"
echo "================================="
echo ""
echo "🔥 OPTION A - FULL AUTOMATED BUILD (Recommended):"
echo "   ./complete_build.sh"
echo "   ⏰ Time: ~30-45 minutes (includes downloads)"
echo "   📦 Downloads: Ubuntu ISO (~4GB) + compiles everything"
echo ""
echo "🛠️  OPTION B - STEP BY STEP BUILD:"
echo "   1. ./quick_setup.sh          # Basic setup (5 min)"
echo "   2. ./modify_driver.sh        # Modify driver (1 min)"  
echo "   3. ./auto_compile.sh         # Compile kernel (20-30 min)"
echo "   4. Download ISO manually if needed"
echo ""
echo "🚀 OPTION C - TESTING (if already built):"
echo "   ./vm_manager.sh install      # Install Ubuntu in VM"
echo "   ./vm_manager.sh boot-custom  # Boot with custom kernel"
echo ""

# Show system info
echo "💻 SYSTEM INFO:"
echo "   CPU cores: $(nproc)"
echo "   Available RAM: $(free -h | awk '/^Mem:/ {print $7}')"
echo "   Free disk space: $(df -h . | awk 'NR==2 {print $4}')"
echo ""

# Show important notes
echo "📝 IMPORTANT NOTES:"
echo "   • Compilation takes 15-30 minutes depending on system"
echo "   • VM requires 6GB RAM (total system should have 8GB+)"
echo "   • Ubuntu ISO is ~4GB download"
echo "   • Final kernel with modules ~2GB"
echo ""

echo "🏃 READY TO START!"
echo ""
echo "Choose an option above and run the corresponding command."
echo "For full automation, simply run: ./complete_build.sh"
echo ""
echo "📖 For detailed instructions, see README.md"
echo "📊 For project status, see STATUS_REPORT.md"
