#!/bin/bash

# VM Management Helper Scripts
# This file contains various helper functions for managing the VM

PROJECT_DIR="/workspaces/Kernel/project"
KERNEL_VERSION="6.6"
KERNEL_DIR="linux-${KERNEL_VERSION}"
UBUNTU_ISO_NAME="ubuntu-24.04.3-desktop-amd64.iso"
VM_DISK="linux.qcow2"
VM_MEMORY="6G"

cd "$PROJECT_DIR"

# Function to install Ubuntu in VM
install_ubuntu_vm() {
    echo "Starting Ubuntu installation in VM..."
    echo "Follow the on-screen instructions to install Ubuntu"
    echo "This will open a graphical interface for Ubuntu installation"
    qemu-system-x86_64 -enable-kvm -m "$VM_MEMORY" -cdrom "$UBUNTU_ISO_NAME" -boot d "$VM_DISK"
}

# Function to boot VM normally
boot_vm() {
    echo "Booting VM with standard kernel..."
    qemu-system-x86_64 -enable-kvm -m "$VM_MEMORY" "$VM_DISK"
}

# Function to boot VM with custom kernel
boot_vm_custom_kernel() {
    echo "Booting VM with custom kernel..."
    echo "Make sure the kernel has been compiled first!"
    
    if [ ! -f "$KERNEL_DIR/arch/x86_64/boot/bzImage" ]; then
        echo "Error: Custom kernel not found. Please run setup_kernel_vm.sh first."
        exit 1
    fi
    
    qemu-system-x86_64 -enable-kvm \
        -kernel "./$KERNEL_DIR/arch/x86_64/boot/bzImage" \
        -append "root=/dev/sda2 console=ttyS0 nokaslr" \
        -m "$VM_MEMORY" \
        -hda "$VM_DISK" \
        -netdev user,id=net0 \
        -device e1000,netdev=net0
}

# Function to get host IP
get_host_ip() {
    echo "Host IP addresses:"
    ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d'/' -f1
}

# Function to transfer files to VM
transfer_to_vm() {
    local file="$1"
    local vm_user="$2"
    local vm_ip="$3"
    
    if [ -z "$file" ] || [ -z "$vm_user" ] || [ -z "$vm_ip" ]; then
        echo "Usage: transfer_to_vm <file> <vm_username> <vm_ip>"
        echo "Example: transfer_to_vm lib.tar.bz2 ubuntu 192.168.122.XXX"
        return 1
    fi
    
    echo "Transferring $file to VM..."
    scp "$file" "$vm_user@$vm_ip:~/"
}

# Function to transfer files from VM
transfer_from_vm() {
    local file="$1"
    local vm_user="$2"
    local vm_ip="$3"
    local dest="${4:-.}"
    
    if [ -z "$file" ] || [ -z "$vm_user" ] || [ -z "$vm_ip" ]; then
        echo "Usage: transfer_from_vm <file> <vm_username> <vm_ip> [destination]"
        echo "Example: transfer_from_vm out.txt ubuntu 192.168.122.XXX ."
        return 1
    fi
    
    echo "Transferring $file from VM to $dest..."
    scp "$vm_user@$vm_ip:~/$file" "$dest"
}

# Main menu
show_menu() {
    echo "=== VM Management Menu ==="
    echo "1. Install Ubuntu in VM"
    echo "2. Boot VM (standard kernel)"
    echo "3. Boot VM with custom kernel"
    echo "4. Show host IP addresses"
    echo "5. Transfer lib.tar.bz2 to VM"
    echo "6. Transfer e1000.ko to VM"
    echo "7. Transfer out.txt from VM"
    echo "8. Exit"
    echo ""
}

# Main script logic
if [ "$#" -eq 0 ]; then
    while true; do
        show_menu
        read -p "Choose an option (1-8): " choice
        
        case $choice in
            1)
                install_ubuntu_vm
                ;;
            2)
                boot_vm
                ;;
            3)
                boot_vm_custom_kernel
                ;;
            4)
                get_host_ip
                ;;
            5)
                read -p "Enter VM username: " vm_user
                read -p "Enter VM IP: " vm_ip
                transfer_to_vm "lib.tar.bz2" "$vm_user" "$vm_ip"
                ;;
            6)
                read -p "Enter VM username: " vm_user
                read -p "Enter VM IP: " vm_ip
                transfer_to_vm "$KERNEL_DIR/drivers/net/ethernet/intel/e1000/e1000.ko" "$vm_user" "$vm_ip"
                ;;
            7)
                read -p "Enter VM username: " vm_user
                read -p "Enter VM IP: " vm_ip
                transfer_from_vm "out.txt" "$vm_user" "$vm_ip" "."
                ;;
            8)
                echo "Exiting..."
                break
                ;;
            *)
                echo "Invalid option. Please choose 1-8."
                ;;
        esac
        echo ""
    done
else
    # Command line usage
    case "$1" in
        "install")
            install_ubuntu_vm
            ;;
        "boot")
            boot_vm
            ;;
        "boot-custom")
            boot_vm_custom_kernel
            ;;
        "ip")
            get_host_ip
            ;;
        *)
            echo "Usage: $0 [install|boot|boot-custom|ip]"
            echo "Or run without arguments for interactive menu"
            ;;
    esac
fi
