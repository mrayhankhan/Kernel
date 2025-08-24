# Custom Linux Kernel Compilation and VM Testing Project

This project provides a complete automated setup for compiling a custom Linux kernel, creating a virtual machine, and testing kernel modifications.

## Project Structure

```
project/
├── setup_kernel_vm.sh          # Main setup script
├── modify_e1000_driver.sh      # Script to modify the e1000 network driver
├── vm_manager.sh              # VM management utilities
├── vm_guest_operations.sh     # Script to run inside the VM
├── README.md                  # This file
└── (generated files)
    ├── ubuntu-24.04.3-desktop-amd64.iso  # Ubuntu ISO
    ├── linux.qcow2                       # VM disk image
    ├── linux-6.6/                        # Kernel source code
    ├── lib.tar.bz2                       # Compiled kernel modules
    └── lib/                               # Kernel modules directory
```

## Prerequisites

- Ubuntu 20.04 or later (host system)
- At least 8GB RAM (6GB will be allocated to VM)
- At least 30GB free disk space
- Internet connection for downloads

## Quick Start

### Step 1: Initial Setup
```bash
cd /workspaces/Kernel/project
chmod +x *.sh
./setup_kernel_vm.sh
```

This script will:
- Install QEMU and required packages
- Download Ubuntu ISO
- Create VM disk image
- Download and compile Linux kernel
- Prepare kernel modules

### Step 2: Install Ubuntu in VM
```bash
./vm_manager.sh install
```
Follow the Ubuntu installation wizard in the VM.

### Step 3: Modify E1000 Driver
```bash
./modify_e1000_driver.sh
```

### Step 4: Boot VM with Custom Kernel
```bash
./vm_manager.sh boot-custom
```

### Step 5: Complete Testing Inside VM

1. **Copy files to VM** (from host):
   ```bash
   # Get host IP
   ./vm_manager.sh ip
   
   # In VM, copy kernel modules
   scp username@HOST_IP:/workspaces/Kernel/project/lib.tar.bz2 .
   
   # Copy modified driver
   scp username@HOST_IP:/workspaces/Kernel/project/linux-6.6/drivers/net/ethernet/intel/e1000/e1000.ko .
   ```

2. **Run guest operations** (inside VM):
   ```bash
   chmod +x vm_guest_operations.sh
   ./vm_guest_operations.sh
   ```

3. **Copy results back** (from VM to host):
   ```bash
   scp out.txt username@HOST_IP:~/
   ```

## Detailed Instructions

### Manual VM Management

#### Install Ubuntu
```bash
qemu-system-x86_64 -enable-kvm -m 6G -cdrom ubuntu-22.04.3-desktop-amd64.iso -boot d linux.qcow2
```

#### Boot VM (standard kernel)
```bash
qemu-system-x86_64 -enable-kvm -m 6G linux.qcow2
```

#### Boot VM (custom kernel)
```bash
qemu-system-x86_64 -enable-kvm \
    -kernel ./linux-6.6/arch/x86_64/boot/bzImage \
    -append "root=/dev/sda2 console=ttyS0 nokaslr" \
    -m 6G -hda linux.qcow2
```

### Kernel Modification Details

The project modifies the `e1000_xmit_frame` function in the e1000 network driver to log source and destination IP addresses of transmitted packets. The modification adds:

```c
struct iphdr *iph = ip_hdr(skb);
if (iph) {
    __be32 saddr = iph->saddr;
    __be32 daddr = iph->daddr;
    printk("src IP: %pI4, dst IP: %pI4\n", &saddr, &daddr);
}
```

### Network Configuration

The VM uses QEMU's user networking by default. To enable SSH between host and VM:

1. **On host**: Enable SSH service
   ```bash
   sudo systemctl enable ssh
   sudo systemctl start ssh
   ```

2. **Find host IP**:
   ```bash
   ip addr show
   ```

3. **From VM**: Connect to host using the bridge IP (usually 192.168.122.1 or similar)

### Troubleshooting

#### VM Won't Boot with Custom Kernel
- Check that the kernel compiled successfully
- Verify the root partition (adjust `/dev/sda2` if needed)
- Try without `nokaslr` parameter

#### Network Issues
- Ensure e1000 module is loaded: `lsmod | grep e1000`
- Check network interfaces: `ip addr show`
- Verify routing: `ip route show`

#### File Transfer Issues
- Ensure SSH is running on host: `sudo systemctl status ssh`
- Check firewall settings
- Use correct IP addresses

#### Compilation Errors
- Ensure all dependencies are installed
- Check available disk space
- For older kernels, you might need to disable additional security features

## Expected Output

After successful completion, the `out.txt` file should contain kernel debug messages showing IP addresses being logged, similar to:

```
[12345.678901] src IP: 192.168.122.15, dst IP: 8.8.8.8
[12345.678902] src IP: 192.168.122.15, dst IP: 8.8.8.8
[12345.678903] src IP: 192.168.122.15, dst IP: 192.168.122.1
```

## Files Generated

- `ubuntu-22.04.3-desktop-amd64.iso`: Ubuntu installation image
- `linux.qcow2`: VM disk image (20GB)
- `linux-6.6/`: Kernel source code directory
- `lib.tar.bz2`: Compiled kernel modules archive
- `out.txt`: Kernel debug output (generated in VM)

## Notes

- The kernel version used is 6.6 (latest stable) instead of 6.16 which doesn't exist yet
- Memory allocation for VM is 6GB (adjust based on available RAM)
- The e1000 driver modification logs all transmitted IP packets
- SSH setup enables file transfer between host and VM

## Security Considerations

- The VM has full network access
- SSH keys should be properly configured for production use
- The modified kernel driver logs network traffic (privacy implications)

## Support

If you encounter issues:
1. Check the troubleshooting section
2. Verify all prerequisites are met
3. Ensure sufficient disk space and memory
4. Check kernel compilation logs for errors
