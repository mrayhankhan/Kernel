# 🏗️ Complete Build and Run Instructions

## 📋 Table of Contents
1. [Quick Start (5 minutes)](#quick-start)
2. [Detailed Build Process](#detailed-build-process)
3. [Testing Instructions](#testing-instructions)
4. [Manual Commands](#manual-commands)
5. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

**For the impatient - get started in 5 minutes:**

```bash
# 1. Go to project directory
cd /workspaces/Kernel/project

# 2. Run quick start guide
./QUICK_START.sh

# 3. Choose full automated build
./complete_build.sh

# That's it! ☕ Grab coffee and wait 30-45 minutes
```

---

## 🔧 Detailed Build Process

### Phase 1: Environment Setup

1. **Navigate to project**:
   ```bash
   cd /workspaces/Kernel/project
   ls -la  # Should see all .sh scripts
   ```

2. **Check system requirements**:
   ```bash
   # Minimum requirements check
   free -h          # Should show 8GB+ total RAM
   df -h .          # Should show 30GB+ free space
   nproc            # Shows CPU cores (more = faster compilation)
   ```

3. **Install dependencies** (if needed):
   ```bash
   sudo apt update
   sudo apt install -y qemu-system-x86 qemu-utils build-essential \
                       flex bison libelf-dev libssl-dev libdw-dev \
                       gawk bc kmod cpio libncurses-dev wget openssh-server
   ```

### Phase 2: Basic Setup

1. **Run basic setup**:
   ```bash
   ./quick_setup.sh
   ```
   
   **What it does:**
   - Creates 20GB VM disk (`linux.qcow2`)
   - Downloads Linux kernel 6.6 source (133MB)
   - Extracts kernel to `linux-6.6/` directory
   - Applies basic configuration
   
   **Expected output:**
   ```
   === Quick Kernel Setup ===
   Creating VM disk image...
   Downloading kernel 6.6 source...
   Extracting kernel source...
   Configuring kernel...
   === Basic setup complete ===
   ```

### Phase 3: Driver Modification

1. **Modify the e1000 network driver**:
   ```bash
   ./modify_driver.sh
   ```
   
   **What it does:**
   - Backs up original `e1000_main.c`
   - Adds IP logging code to `e1000_xmit_frame` function
   - Logs source and destination IP addresses
   
   **Expected output:**
   ```
   === E1000 Driver Modification ===
   Creating backup of original driver...
   Modifying e1000_main.c...
   Successfully modified e1000_main.c
   Added IP logging to e1000_xmit_frame function
   ```

2. **Verify modification**:
   ```bash
   grep -A 5 -B 5 "src IP:" linux-6.6/drivers/net/ethernet/intel/e1000/e1000_main.c
   ```
   
   **Should show:**
   ```c
   /* Custom IP logging modification */
   struct iphdr *iph = ip_hdr(skb);
   if (iph) {
       __be32 saddr = iph->saddr;
       __be32 daddr = iph->daddr;
       printk("src IP: %pI4, dst IP: %pI4\n", &saddr, &daddr);
   }
   ```

### Phase 4: Kernel Compilation

1. **Start full compilation**:
   ```bash
   ./complete_build.sh
   ```
   
   **What it does:**
   - Downloads Ubuntu 24.04 ISO (~4GB)
   - Compiles Linux kernel (15-30 minutes)
   - Installs kernel modules
   - Compiles modified e1000 driver
   - Creates module archive
   
   **Progress indicators:**
   ```
   Step 1: Checking Ubuntu ISO...
   Step 2: Completing kernel compilation...
   Step 3: Installing kernel modules...
   Step 4: Creating modules archive...
   Step 5: Compiling modified e1000 driver...
   ```

2. **Monitor compilation** (in another terminal):
   ```bash
   # Watch build progress
   tail -f /workspaces/Kernel/project/kernel_build.log
   
   # Check CPU usage
   htop
   
   # Check disk usage
   watch -n 5 'df -h /workspaces/Kernel/project'
   ```

### Phase 5: Verification

1. **Check build results**:
   ```bash
   ls -la linux-6.6/arch/x86_64/boot/bzImage    # Kernel image
   ls -la lib.tar.bz2                           # Kernel modules
   ls -la linux-6.6/drivers/net/ethernet/intel/e1000/e1000.ko  # Modified driver
   ls -la ubuntu-24.04.3-desktop-amd64.iso     # Ubuntu ISO
   ```

2. **Check file sizes**:
   ```bash
   du -h linux-6.6/arch/x86_64/boot/bzImage    # ~8-15MB
   du -h lib.tar.bz2                           # ~200-500MB
   du -h ubuntu-24.04.3-desktop-amd64.iso     # ~4GB
   ```

---

## 🧪 Testing Instructions

### Stage 1: VM Installation

1. **Install Ubuntu in VM**:
   ```bash
   ./vm_manager.sh install
   ```
   
   **Manual command:**
   ```bash
   qemu-system-x86_64 -enable-kvm -m 6G \
       -cdrom ubuntu-24.04.3-desktop-amd64.iso \
       -boot d linux.qcow2
   ```

2. **Ubuntu installation steps**:
   - Choose "Install Ubuntu"
   - Select language and keyboard
   - Choose "Normal installation"
   - Select "Erase disk and install Ubuntu"
   - Create user account (remember username/password)
   - Wait for installation (10-20 minutes)
   - Restart when prompted

### Stage 2: Standard Kernel Test

1. **Boot with standard kernel**:
   ```bash
   ./vm_manager.sh boot
   ```
   
   **Verify Ubuntu works:**
   - Login with your credentials
   - Open terminal
   - Test network: `ping google.com`
   - Check kernel: `uname -r`
   - Shutdown: `sudo shutdown -h now`

### Stage 3: Custom Kernel Test

1. **Boot with custom kernel**:
   ```bash
   ./vm_manager.sh boot-custom
   ```
   
   **Manual command:**
   ```bash
   qemu-system-x86_64 -enable-kvm \
       -kernel ./linux-6.6/arch/x86_64/boot/bzImage \
       -append "root=/dev/sda2 console=ttyS0 nokaslr" \
       -m 6G -hda linux.qcow2
   ```

2. **Login and verify custom kernel**:
   ```bash
   uname -r    # Should show 6.6.0 or similar
   lsmod | grep e1000   # Should NOT show e1000 yet
   ```

### Stage 4: Install Custom Modules

1. **Get host IP** (on host machine):
   ```bash
   ./vm_manager.sh ip
   # Or: hostname -I | awk '{print $1}'
   ```

2. **Transfer files to VM** (in VM):
   ```bash
   # Replace HOST_IP with actual IP from step 1
   scp username@HOST_IP:/workspaces/Kernel/project/lib.tar.bz2 .
   scp username@HOST_IP:/workspaces/Kernel/project/linux-6.6/drivers/net/ethernet/intel/e1000/e1000.ko .
   scp username@HOST_IP:/workspaces/Kernel/project/vm_guest_operations.sh .
   ```

3. **Install modules and test** (in VM):
   ```bash
   chmod +x vm_guest_operations.sh
   ./vm_guest_operations.sh
   ```

### Stage 5: Verify IP Logging

1. **Check for IP logging output** (in VM):
   ```bash
   sudo dmesg | grep -E "(src IP|dst IP)"
   ```
   
   **Expected output:**
   ```
   [12345.678901] src IP: 192.168.122.15, dst IP: 8.8.8.8
   [12345.678902] src IP: 192.168.122.15, dst IP: 192.168.122.1
   [12345.678903] src IP: 192.168.122.15, dst IP: 8.8.8.8
   ```

2. **Generate more traffic and test** (in VM):
   ```bash
   # Generate various network traffic
   ping -c 5 google.com
   curl -s http://example.com > /dev/null
   wget -q --timeout=5 http://httpbin.org/ip -O /dev/null
   
   # Check logs again
   sudo dmesg | grep -E "(src IP|dst IP)" | tail -10
   ```

3. **Save results** (in VM):
   ```bash
   sudo dmesg > out.txt
   echo "IP Logging Test Results:" >> out.txt
   echo "========================" >> out.txt
   sudo dmesg | grep -E "(src IP|dst IP)" >> out.txt
   
   # Copy back to host
   scp out.txt username@HOST_IP:~/kernel_test_results.txt
   ```

---

## 📖 Manual Commands Reference

### Kernel Compilation Commands
```bash
# Basic configuration
cd linux-6.6
make defconfig

# Custom configuration
make menuconfig

# Compile kernel
make -j$(nproc)

# Install modules locally
make modules_install INSTALL_MOD_PATH=../

# Compile specific driver
make M=drivers/net/ethernet/intel/e1000

# Clean build
make clean
make mrproper
```

### VM Management Commands
```bash
# Create VM disk
qemu-img create -f qcow2 linux.qcow2 20G

# Install OS
qemu-system-x86_64 -enable-kvm -m 6G -cdrom ubuntu.iso -boot d linux.qcow2

# Boot normally
qemu-system-x86_64 -enable-kvm -m 6G linux.qcow2

# Boot with custom kernel
qemu-system-x86_64 -enable-kvm \
    -kernel ./linux-6.6/arch/x86_64/boot/bzImage \
    -append "root=/dev/sda2 console=ttyS0 nokaslr" \
    -m 6G -hda linux.qcow2

# Boot with networking options
qemu-system-x86_64 -enable-kvm -m 6G linux.qcow2 \
    -netdev user,id=net0 -device e1000,netdev=net0
```

### File Transfer Commands
```bash
# Host to VM
scp file.txt username@VM_IP:~/

# VM to Host
scp username@HOST_IP:/path/to/file.txt .

# Directory transfer
scp -r directory/ username@HOST_IP:~/

# With specific port
scp -P 2222 file.txt username@HOST_IP:~/
```

### Debugging Commands
```bash
# Check kernel messages
dmesg
sudo dmesg | grep -i error
sudo dmesg | tail -50

# Check loaded modules
lsmod
lsmod | grep e1000

# Check network interfaces
ip addr show
ifconfig

# Check network traffic
sudo tcpdump -i any
sudo netstat -i

# System information
uname -a
cat /proc/version
cat /proc/cpuinfo
free -h
df -h
```

---

## 🚨 Troubleshooting

### Compilation Issues

**Problem**: "No space left on device"
```bash
# Solution: Check and free space
df -h
sudo apt autoremove
sudo apt autoclean
# Move project to larger partition if needed
```

**Problem**: "Permission denied" during compilation
```bash
# Solution: Check permissions
ls -la
chmod +x *.sh
sudo chown -R $USER:$USER .
```

**Problem**: Missing dependencies error
```bash
# Solution: Install missing packages
sudo apt update
sudo apt install build-essential linux-headers-$(uname -r)
# Run dependency installation again
```

### VM Issues

**Problem**: VM doesn't start or crashes
```bash
# Check KVM support
kvm-ok
sudo modprobe kvm
sudo modprobe kvm_intel  # or kvm_amd

# Check QEMU installation
qemu-system-x86_64 --version

# Try without KVM
qemu-system-x86_64 -m 6G linux.qcow2  # Remove -enable-kvm
```

**Problem**: Custom kernel doesn't boot
```bash
# Check kernel image exists
ls -la linux-6.6/arch/x86_64/boot/bzImage

# Try different append options
-append "root=/dev/sda1 console=ttyS0"  # Try sda1 instead of sda2
-append "root=/dev/sda2 console=tty0"   # Try tty0 instead of ttyS0

# Boot with more verbose output
-append "root=/dev/sda2 console=ttyS0 debug loglevel=7"
```

**Problem**: Network doesn't work in VM
```bash
# Check network interface
ip addr show

# Restart networking
sudo systemctl restart networking

# Load e1000 driver manually
sudo modprobe e1000
lsmod | grep e1000
```

### File Transfer Issues

**Problem**: SSH connection refused
```bash
# On host: Start SSH service
sudo systemctl start ssh
sudo systemctl enable ssh

# Check SSH is listening
sudo netstat -tlnp | grep :22

# Check firewall
sudo ufw status
sudo ufw allow ssh
```

**Problem**: Cannot find host IP
```bash
# Get all network interfaces
ip addr show
ifconfig -a

# Common host IPs for VMs
# Try: 192.168.122.1, 10.0.2.2, or bridge IP
```

### Driver Issues

**Problem**: Modified driver doesn't load
```bash
# Check driver file exists
ls -la linux-6.6/drivers/net/ethernet/intel/e1000/e1000.ko

# Check driver dependencies
modinfo e1000.ko

# Load with force if needed
sudo insmod e1000.ko

# Check kernel messages for errors
dmesg | tail -20
```

**Problem**: No IP logging output
```bash
# Check if e1000 is actually loaded
lsmod | grep e1000

# Generate specific traffic
ping -c 1 8.8.8.8

# Check dmesg immediately
sudo dmesg | tail -10

# Verify driver modification
grep -A 5 "src IP:" /path/to/e1000_main.c
```

---

## ✅ Success Checklist

Mark each item when completed:

### Build Phase
- [ ] All dependencies installed
- [ ] Kernel source downloaded and extracted
- [ ] Driver successfully modified
- [ ] Kernel compiles without errors
- [ ] Modules compiled and archived
- [ ] Ubuntu ISO downloaded

### Testing Phase
- [ ] VM disk created successfully
- [ ] Ubuntu installed in VM
- [ ] VM boots with standard kernel
- [ ] VM boots with custom kernel
- [ ] Custom modules transferred to VM
- [ ] Modified driver loads successfully
- [ ] Network traffic generates IP logs
- [ ] Results captured and saved

### Verification
- [ ] IP logging output visible in dmesg
- [ ] Multiple IP addresses logged
- [ ] Both source and destination IPs shown
- [ ] Results saved to file
- [ ] No critical errors in kernel log

**🎉 Project complete when all items are checked!**

---

## 📞 Getting Help

1. **Check build logs**:
   - `kernel_build.log` - Kernel compilation log
   - `e1000_build.log` - Driver compilation log

2. **Review status**:
   - `STATUS_REPORT.md` - Detailed project status
   - `./QUICK_START.sh` - Run status check

3. **Common solutions**:
   - Restart from clean state: Remove `linux-6.6/` and re-run `quick_setup.sh`
   - Memory issues: Reduce VM memory to 4G: `-m 4G`
   - Network issues: Use different network mode in QEMU

4. **Verification commands**:
   ```bash
   # Check everything is ready
   ls -la linux-6.6/arch/x86_64/boot/bzImage
   ls -la lib.tar.bz2
   ls -la ubuntu-24.04.3-desktop-amd64.iso
   ls -la linux.qcow2
   ```

**Total estimated time: 2-4 hours (including compilation)**
