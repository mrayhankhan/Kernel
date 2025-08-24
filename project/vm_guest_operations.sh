#!/bin/bash

# VM Guest Operations Script
# This script should be run INSIDE the VM to complete the kernel testing

set -e

echo "=== VM Guest Operations for Custom Kernel Testing ==="

# Step 1: Extract and install kernel modules
echo "Step 1: Installing custom kernel modules..."
if [ -f "lib.tar.bz2" ]; then
    echo "Extracting lib.tar.bz2..."
    tar -xvf lib.tar.bz2
    
    echo "Installing kernel modules..."
    sudo cp -r lib/modules/* /lib/modules/
    
    echo "Running depmod to update module dependencies..."
    sudo depmod -a
    
    echo "Kernel modules installed successfully!"
else
    echo "Warning: lib.tar.bz2 not found. Please copy it from the host first."
    echo "Use: scp username@HOST_IP:/path/to/project/lib.tar.bz2 ."
    exit 1
fi

# Step 2: Load custom e1000 driver
echo "Step 2: Loading custom e1000 driver..."
if [ -f "e1000.ko" ]; then
    echo "Unloading original e1000 module..."
    sudo modprobe -r e1000 || true  # Don't fail if module not loaded
    
    echo "Loading custom e1000 module..."
    sudo insmod e1000.ko
    
    echo "Verifying module is loaded..."
    lsmod | grep e1000
    
    echo "Custom e1000 driver loaded successfully!"
else
    echo "Warning: e1000.ko not found. Please copy it from the host first."
    echo "Use: scp username@HOST_IP:/path/to/project/linux-*/drivers/net/ethernet/intel/e1000/e1000.ko ."
    exit 1
fi

# Step 3: Test network connectivity and capture logs
echo "Step 3: Testing network connectivity..."

# Clear previous kernel messages
sudo dmesg -c > /dev/null

echo "Pinging Google to generate network traffic..."
ping -c 5 www.google.com

echo "Pinging host to generate more traffic..."
read -p "Enter host IP address: " host_ip
ping -c 3 "$host_ip" || echo "Host ping failed, but that's okay"

# Generate some additional network traffic
echo "Generating additional network traffic..."
curl -s http://www.google.com > /dev/null || true
wget -q --timeout=5 http://www.example.com -O /dev/null || true

echo "Step 4: Capturing kernel debug messages..."
sudo dmesg > out.txt

echo "Displaying recent kernel messages with IP logging:"
echo "=========================================="
sudo dmesg | grep -E "(src IP|dst IP)" | tail -20
echo "=========================================="

echo "Kernel messages saved to out.txt"
echo "File size: $(wc -l < out.txt) lines"

echo "Step 5: Network interface information..."
echo "Current network interfaces:"
ip addr show

echo "Routing table:"
ip route show

echo "=== Testing Complete ==="
echo "The out.txt file contains all kernel debug messages."
echo "You can now copy it back to the host using:"
echo "scp out.txt username@$host_ip:~/"

# Optional: Show summary of IP addresses logged
echo ""
echo "Summary of logged IP addresses:"
sudo dmesg | grep -E "src IP:" | tail -10
