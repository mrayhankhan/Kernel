#!/bin/bash

# Script to modify the e1000 driver and test the custom kernel
# This script should be run after the initial setup and VM installation

set -e

PROJECT_DIR="/workspaces/Kernel/project"
KERNEL_VERSION="6.6"
KERNEL_DIR="linux-${KERNEL_VERSION}"
E1000_DRIVER_PATH="drivers/net/ethernet/intel/e1000/e1000_main.c"

echo "=== E1000 Driver Modification Script ==="
cd "$PROJECT_DIR/$KERNEL_DIR"

# Backup the original driver
if [ ! -f "${E1000_DRIVER_PATH}.backup" ]; then
    echo "Creating backup of original e1000_main.c..."
    cp "$E1000_DRIVER_PATH" "${E1000_DRIVER_PATH}.backup"
fi

echo "Modifying e1000 driver to add IP logging..."

# The modification will be done using a more robust method
# We'll create a patch that adds the IP logging functionality

cat > e1000_modification.patch << 'EOF'
--- a/drivers/net/ethernet/intel/e1000/e1000_main.c
+++ b/drivers/net/ethernet/intel/e1000/e1000_main.c
@@ -3095,6 +3095,15 @@ static netdev_tx_t e1000_xmit_frame(struct sk_buff *skb,
 	unsigned int len = skb_headlen(skb);
 	unsigned int nr_frags;
 	unsigned int mss;
+	
+	/* Add IP logging functionality */
+	struct iphdr *iph = ip_hdr(skb);
+	if (iph) {
+		__be32 saddr = iph->saddr;
+		__be32 daddr = iph->daddr;
+		printk("src IP: %pI4, dst IP: %pI4\n", &saddr, &daddr);
+	}
+	
 	int count = 0;
 	int tso;
 	unsigned int f;
EOF

# Apply the patch (if it fails, we'll do manual modification)
if ! patch -p1 < e1000_modification.patch; then
    echo "Patch failed, applying manual modification..."
    
    # Manual modification using sed (more reliable for this specific case)
    # Find the e1000_xmit_frame function and add our logging code
    python3 << 'PYTHON_SCRIPT'
import re

# Read the file
with open('drivers/net/ethernet/intel/e1000/e1000_main.c', 'r') as f:
    content = f.read()

# Find the e1000_xmit_frame function and add our code after the variable declarations
pattern = r'(static netdev_tx_t e1000_xmit_frame\(struct sk_buff \*skb,.*?\n.*?unsigned int mss;)'
replacement = r'''\1
	
	/* Add IP logging functionality */
	struct iphdr *iph = ip_hdr(skb);
	if (iph) {
		__be32 saddr = iph->saddr;
		__be32 daddr = iph->daddr;
		printk("src IP: %pI4, dst IP: %pI4\n", &saddr, &daddr);
	}'''

modified_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Write back to file
with open('drivers/net/ethernet/intel/e1000/e1000_main.c', 'w') as f:
    f.write(modified_content)

print("Manual modification applied successfully")
PYTHON_SCRIPT
fi

echo "Compiling modified e1000 module..."
make M=drivers/net/ethernet/intel/e1000

echo "=== E1000 Driver Modified Successfully ==="
echo "The modified driver is ready at: $KERNEL_DIR/drivers/net/ethernet/intel/e1000/e1000.ko"
echo ""
echo "Next steps:"
echo "1. Boot your VM with the custom kernel"
echo "2. Copy the modified driver to the VM"
echo "3. Load the modified driver and test"
