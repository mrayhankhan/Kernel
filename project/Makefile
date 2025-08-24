# Makefile for Custom Linux Kernel VM Project
# This Makefile automates the kernel compilation and VM setup process

.PHONY: all setup clean install-vm boot-vm boot-custom modify-driver help

# Variables
PROJECT_DIR := /workspaces/Kernel/project
KERNEL_VERSION := 6.6
KERNEL_DIR := linux-$(KERNEL_VERSION)
VM_DISK := linux.qcow2
UBUNTU_ISO := ubuntu-22.04.3-desktop-amd64.iso

# Default target
all: setup modify-driver
	@echo "=== Build Complete ==="
	@echo "Next steps:"
	@echo "1. make install-vm    # Install Ubuntu in VM"
	@echo "2. make boot-custom   # Boot VM with custom kernel"
	@echo "3. Follow README.md for VM operations"

# Setup everything (download, compile kernel, etc.)
setup:
	@echo "=== Setting up project ==="
	chmod +x *.sh
	./setup_kernel_vm.sh

# Modify the e1000 driver
modify-driver:
	@echo "=== Modifying e1000 driver ==="
	./modify_e1000_driver.sh

# Install Ubuntu in VM
install-vm:
	@echo "=== Installing Ubuntu in VM ==="
	./vm_manager.sh install

# Boot VM with standard kernel
boot-vm:
	@echo "=== Booting VM with standard kernel ==="
	./vm_manager.sh boot

# Boot VM with custom kernel
boot-custom:
	@echo "=== Booting VM with custom kernel ==="
	./vm_manager.sh boot-custom

# Show host IP addresses
show-ip:
	@echo "=== Host IP Addresses ==="
	./vm_manager.sh ip

# Clean build artifacts (but keep downloads)
clean:
	@echo "=== Cleaning build artifacts ==="
	rm -rf $(KERNEL_DIR)
	rm -f lib.tar.bz2
	rm -rf lib/
	@echo "Cleaned build artifacts (kept downloads and VM)"

# Deep clean (remove everything including downloads and VM)
deep-clean:
	@echo "=== Deep cleaning all files ==="
	rm -rf $(KERNEL_DIR)
	rm -f lib.tar.bz2
	rm -rf lib/
	rm -f $(UBUNTU_ISO)
	rm -f $(VM_DISK)
	@echo "Deep clean complete"

# Check system requirements
check-deps:
	@echo "=== Checking dependencies ==="
	@command -v qemu-system-x86_64 >/dev/null 2>&1 || echo "ERROR: QEMU not installed"
	@command -v gcc >/dev/null 2>&1 || echo "ERROR: GCC not installed"
	@command -v make >/dev/null 2>&1 || echo "OK: Make is available"
	@command -v wget >/dev/null 2>&1 || echo "ERROR: wget not installed"
	@command -v ssh >/dev/null 2>&1 || echo "ERROR: SSH not installed"
	@echo "Dependency check complete"

# Show project status
status:
	@echo "=== Project Status ==="
	@echo "Project directory: $(PROJECT_DIR)"
	@echo "Kernel version: $(KERNEL_VERSION)"
	@echo ""
	@echo "Files present:"
	@ls -la $(PROJECT_DIR) 2>/dev/null || echo "Project directory not found"
	@echo ""
	@echo "VM disk: $(if $(wildcard $(VM_DISK)),✓ Present,✗ Missing)"
	@echo "Ubuntu ISO: $(if $(wildcard $(UBUNTU_ISO)),✓ Present,✗ Missing)"
	@echo "Kernel source: $(if $(wildcard $(KERNEL_DIR)),✓ Present,✗ Missing)"
	@echo "Kernel modules: $(if $(wildcard lib.tar.bz2),✓ Present,✗ Missing)"

# Quick kernel recompile (after modifications)
recompile:
	@echo "=== Recompiling kernel ==="
	cd $(KERNEL_DIR) && make -j$(shell nproc)
	cd $(KERNEL_DIR) && make modules_install INSTALL_MOD_PATH=../
	tar -cvf lib.tar.bz2 lib

# Recompile just the e1000 module
recompile-e1000:
	@echo "=== Recompiling e1000 module ==="
	cd $(KERNEL_DIR) && make M=drivers/net/ethernet/intel/e1000

# Create a backup of the current state
backup:
	@echo "=== Creating project backup ==="
	tar -czf kernel_project_backup_$(shell date +%Y%m%d_%H%M%S).tar.gz \
		--exclude='*.iso' --exclude='*.qcow2' .
	@echo "Backup created (excluding large files)"

# Development target - setup for development
dev-setup: setup
	@echo "=== Development setup complete ==="
	@echo "Useful commands:"
	@echo "  make recompile        # Recompile full kernel"
	@echo "  make recompile-e1000  # Recompile just e1000 module"
	@echo "  make status           # Show project status"
	@echo "  make backup           # Create backup"

# Help target
help:
	@echo "Custom Linux Kernel VM Project - Makefile Help"
	@echo ""
	@echo "Main targets:"
	@echo "  all              - Complete setup and build"
	@echo "  setup            - Download and compile kernel"
	@echo "  modify-driver    - Modify e1000 driver"
	@echo "  install-vm       - Install Ubuntu in VM"
	@echo "  boot-vm          - Boot VM with standard kernel"
	@echo "  boot-custom      - Boot VM with custom kernel"
	@echo ""
	@echo "Utility targets:"
	@echo "  status           - Show project status"
	@echo "  show-ip          - Show host IP addresses"
	@echo "  check-deps       - Check system dependencies"
	@echo "  clean            - Clean build artifacts"
	@echo "  deep-clean       - Remove all files"
	@echo ""
	@echo "Development targets:"
	@echo "  dev-setup        - Setup for development"
	@echo "  recompile        - Recompile full kernel"
	@echo "  recompile-e1000  - Recompile e1000 module only"
	@echo "  backup           - Create project backup"
	@echo ""
	@echo "For detailed instructions, see README.md"
