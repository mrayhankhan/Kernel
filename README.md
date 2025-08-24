# Custom Linux Kernel Compilation and VM Testing Project

This project demonstrates how to compile a custom Linux kernel with modified network drivers and test it in a virtual machine environment. The project includes automated scripts for the entire process from kernel compilation to VM testing.

## 🎯 Project Overview

**Goal**: Compile a custom Linux kernel with a modified e1000 network driver that logs IP addresses of transmitted packets, then test it in an Ubuntu virtual machine.

**What you'll achieve**:
- Custom Linux kernel compilation
- Network driver modification (e1000 with IP logging)
- Virtual machine setup and testing
- Real-world kernel development experience

## 📋 Prerequisites

- Ubuntu 20.04+ or similar Linux distribution
- At least 8GB RAM (6GB for VM)
- 30GB+ free disk space
- Internet connection for downloads
- Basic Linux command line knowledge

## 🚀 Complete Step-by-Step Build Instructions

### Step 1: Initial Setup

1. **Clone and navigate to the project**:
   ```bash
   cd /workspaces/Kernel
   ls -la  # You should see project/ directory and this README
   ```

2. **Enter the project directory**:
   ```bash
   cd project
   ```

3. **Make all scripts executable**:
   ```bash
   chmod +x *.sh
   ```

### Step 2: System Dependencies and Basic Setup

1. **Install required packages** (if not already installed):
   ```bash
   sudo apt update
   sudo apt install -y qemu-system-x86 qemu-utils build-essential flex bison \
                       libelf-dev libssl-dev libdw-dev gawk bc kmod cpio \
                       libncurses-dev wget openssh-server
   ```

2. **Run the quick setup** (downloads kernel, creates VM disk):
   ```bash
   ./quick_setup.sh
   ```
   
   This will:
   - Create a 20GB VM disk image
   - Download Linux kernel 6.6 source (133MB)
   - Extract and configure the kernel
   - Apply basic configuration

### Step 3: Modify the Network Driver

1. **Apply the e1000 driver modification**:
   ```bash
   ./modify_driver.sh
   ```
   
   This modifies the e1000 network driver to log IP addresses of transmitted packets.

### Step 4: Compile the Custom Kernel

1. **Start the complete build process**:
   ```bash
   ./complete_build.sh
   ```
   
   This will:
   - Download Ubuntu 24.04 ISO (~4GB)
   - Compile the kernel (15-30 minutes)
   - Install kernel modules
   - Compile the modified e1000 driver
   - Create module archives

   ⏰ **Note**: Kernel compilation takes 15-30 minutes depending on your system.

### Step 5: Virtual Machine Setup

1. **Install Ubuntu in the VM**:
   ```bash
   ./vm_manager.sh install
   ```
   
   Or manually:
   ```bash
   qemu-system-x86_64 -enable-kvm -m 6G -cdrom ubuntu-24.04.3-desktop-amd64.iso -boot d linux.qcow2
   ```

2. **Follow the Ubuntu installation wizard** in the VM window
   - Choose installation options
   - Create user account
   - Complete installation
   - Shutdown the VM when done

### Step 6: Test with Standard Kernel (Optional)

1. **Boot VM with standard kernel**:
   ```bash
   ./vm_manager.sh boot
   ```
   
   Or manually:
   ```bash
   qemu-system-x86_64 -enable-kvm -m 6G linux.qcow2
   ```

2. **Verify Ubuntu is working properly**, then shutdown

### Step 7: Boot with Custom Kernel

1. **Boot VM with your custom kernel**:
   ```bash
   ./vm_manager.sh boot-custom
   ```
   
   Or manually:
   ```bash
   qemu-system-x86_64 -enable-kvm \
       -kernel ./linux-6.6/arch/x86_64/boot/bzImage \
       -append "root=/dev/sda2 console=ttyS0 nokaslr" \
       -m 6G -hda linux.qcow2
   ```

### Step 8: Install Custom Kernel Modules in VM

1. **Find your host machine's IP address**:
   ```bash
   ./vm_manager.sh ip
   # Or: ip addr show | grep "inet " | grep -v "127.0.0.1"
   ```

2. **In the VM, copy the kernel modules**:
   ```bash
   # Replace HOST_IP with your actual host IP
   scp username@HOST_IP:/workspaces/Kernel/project/lib.tar.bz2 .
   ```

3. **In the VM, copy the modified driver**:
   ```bash
   scp username@HOST_IP:/workspaces/Kernel/project/linux-6.6/drivers/net/ethernet/intel/e1000/e1000.ko .
   ```

4. **In the VM, run the installation script**:
   ```bash
   # First copy the script to VM
   scp username@HOST_IP:/workspaces/Kernel/project/vm_guest_operations.sh .
   chmod +x vm_guest_operations.sh
   ./vm_guest_operations.sh
   ```

### Step 9: Test the Modified Driver

1. **In the VM, the script will**:
   - Install kernel modules
   - Load the modified e1000 driver
   - Generate network traffic
   - Capture kernel logs

2. **View the IP logging output**:
   ```bash
   # In the VM
   sudo dmesg | grep -E "(src IP|dst IP)"
   ```
   
   You should see output like:
   ```
   [12345.678901] src IP: 192.168.122.15, dst IP: 8.8.8.8
   [12345.678902] src IP: 192.168.122.15, dst IP: 192.168.122.1
   ```

3. **Save the results**:
   ```bash
   # In the VM
   sudo dmesg > out.txt
   
   # Copy back to host
   scp out.txt username@HOST_IP:~/
   ```

## 📁 Project Structure

```
project/
├── Makefile                      # Build automation
├── README.md                     # This file
├── STATUS_REPORT.md             # Detailed project status
├── complete_build.sh            # Complete build automation
├── quick_setup.sh              # Initial setup
├── modify_driver.sh            # Driver modification
├── vm_manager.sh               # VM management utilities
├── vm_guest_operations.sh      # Scripts to run in VM
├── linux-6.6/                 # Kernel source directory
│   └── drivers/net/ethernet/intel/e1000/
│       ├── e1000_main.c        # Modified driver
│       └── e1000_main.c.backup # Original backup
├── linux-6.6.tar.xz          # Kernel source archive
├── ubuntu-24.04.3-desktop-amd64.iso  # Ubuntu ISO
├── linux.qcow2               # VM disk image (20GB)
└── lib.tar.bz2               # Compiled kernel modules
```

## 🔧 Manual Commands Reference

### Kernel Compilation
```bash
cd linux-6.6
make -j$(nproc)                    # Compile kernel
make modules_install INSTALL_MOD_PATH=../  # Install modules
make M=drivers/net/ethernet/intel/e1000    # Compile e1000 driver only
```

### VM Management
```bash
# Create VM disk
qemu-img create -f qcow2 linux.qcow2 20G

# Install Ubuntu
qemu-system-x86_64 -enable-kvm -m 6G -cdrom ubuntu-iso -boot d linux.qcow2

# Boot with standard kernel
qemu-system-x86_64 -enable-kvm -m 6G linux.qcow2

# Boot with custom kernel
qemu-system-x86_64 -enable-kvm -kernel ./linux-6.6/arch/x86_64/boot/bzImage \
    -append "root=/dev/sda2 console=ttyS0 nokaslr" -m 6G -hda linux.qcow2
```

### File Transfers
```bash
# Host to VM
scp file.txt username@VM_IP:~/

# VM to Host  
scp username@HOST_IP:/path/to/file.txt .
```

## 🚨 Troubleshooting

### Kernel Compilation Issues
- **Out of disk space**: Ensure 30GB+ free space
- **Missing dependencies**: Run the dependency installation command again
- **Config errors**: Delete `.config` file and run `make defconfig`

### VM Issues
- **VM won't start**: Check if KVM is enabled: `sudo systemctl status qemu-kvm`
- **No network in VM**: Ensure e1000 driver is loaded: `lsmod | grep e1000`
- **Custom kernel won't boot**: Check kernel messages in QEMU console

### File Transfer Issues
- **SSH connection refused**: Ensure SSH service is running: `sudo systemctl start ssh`
- **Permission denied**: Check SSH keys or use password authentication
- **Network unreachable**: Verify IP addresses with `ip addr show`

## 📊 Expected Results

After successful completion, you should have:

1. **Custom compiled Linux kernel** with your modifications
2. **Modified e1000 driver** that logs IP addresses
3. **Working Ubuntu VM** running your custom kernel
4. **Kernel log output** showing IP address logging like:
   ```
   src IP: 192.168.122.15, dst IP: 8.8.8.8
   src IP: 192.168.122.15, dst IP: 192.168.122.1
   ```

## 🎓 Learning Outcomes

This project teaches:
- Linux kernel compilation process
- Kernel module development and modification
- Network driver internals
- Virtual machine management with QEMU
- System debugging and troubleshooting
- Build automation and scripting

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review `STATUS_REPORT.md` for detailed progress info
3. Check build logs: `kernel_build.log`, `e1000_build.log`
4. Ensure all prerequisites are met

## 🏆 Success Criteria

Your project is successful when:
- ✅ Kernel compiles without errors
- ✅ VM boots with custom kernel
- ✅ Modified e1000 driver loads successfully
- ✅ Network traffic generates IP logging output
- ✅ You can capture and view the kernel debug messages

**Estimated total time**: 2-4 hours (including compilation time)
