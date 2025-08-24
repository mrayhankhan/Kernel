#!/bin/bash

# Driver modification script
# This modifies the e1000 driver to log IP addresses

PROJECT_DIR="/workspaces/Kernel/project"
KERNEL_DIR="$PROJECT_DIR/linux-6.6"
DRIVER_FILE="$KERNEL_DIR/drivers/net/ethernet/intel/e1000/e1000_main.c"

echo "=== E1000 Driver Modification ==="

cd "$KERNEL_DIR"

# Check if kernel source exists
if [ ! -f "$DRIVER_FILE" ]; then
    echo "Error: Driver file not found at $DRIVER_FILE"
    exit 1
fi

# Create backup
echo "Creating backup of original driver..."
cp "$DRIVER_FILE" "${DRIVER_FILE}.backup"

# Find the e1000_xmit_frame function and add logging
echo "Modifying e1000_main.c..."

# Create a Python script to do the modification
python3 << 'EOF'
import re

driver_file = "/workspaces/Kernel/project/linux-6.6/drivers/net/ethernet/intel/e1000/e1000_main.c"

# Read the file
with open(driver_file, 'r') as f:
    content = f.read()

# Look for the function signature and the beginning of the function
pattern = r'(static netdev_tx_t e1000_xmit_frame\(struct sk_buff \*skb,\s*\n\s*struct net_device \*netdev\)\s*\n\{\s*\n)'

# Find the pattern
match = re.search(pattern, content, re.MULTILINE)

if match:
    # Insert our IP logging code right after the opening brace
    new_code = match.group(1) + '''\t/* Custom IP logging modification */
\tstruct iphdr *iph = ip_hdr(skb);
\tif (iph) {
\t\t__be32 saddr = iph->saddr;
\t\t__be32 daddr = iph->daddr;
\t\tprintk("src IP: %pI4, dst IP: %pI4\\n", &saddr, &daddr);
\t}

'''
    
    # Replace the original with our modified version
    modified_content = content[:match.start()] + new_code + content[match.end():]
    
    # Write back
    with open(driver_file, 'w') as f:
        f.write(modified_content)
    
    print("Successfully modified e1000_main.c")
    print("Added IP logging to e1000_xmit_frame function")
else:
    print("Error: Could not find e1000_xmit_frame function")
    exit(1)
EOF

echo "Driver modification complete!"
echo "Modified file: $DRIVER_FILE"
echo "Backup saved as: ${DRIVER_FILE}.backup"
echo ""
echo "The modification adds IP address logging to the e1000 network driver."
echo "When network packets are transmitted, it will log source and destination IPs."
