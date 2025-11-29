#!/bin/bash
set -e

# This test extracts the iptables setup loop from hysteria.sh and verifies it adds the RETURN rule.

SCRIPT_FILE="hysteria.sh"
TEMP_SCRIPT="temp_test_loop.sh"
MAPPING_FILE="test_mapping.txt"

# Create a dummy mapping file
echo "config1.yaml|service1|80,443" > "$MAPPING_FILE"

# Extract the loop. It starts after "# ====== Set up per-config iptables counters ======"
# and ends before "sudo tee /etc/systemd/system/hysteria-monitor.service"
# We'll use sed to extract it.

# Find line numbers
START_LINE=$(grep -n "# ====== Set up per-config iptables counters ======" "$SCRIPT_FILE" | cut -d: -f1)
END_LINE=$(grep -n "sudo tee /etc/systemd/system/hysteria-monitor.service" "$SCRIPT_FILE" | cut -d: -f1)

# Extract lines
sed -n "$((START_LINE+1)),$((END_LINE-1))p" "$SCRIPT_FILE" > "$TEMP_SCRIPT"

# Verify extraction
if [ ! -s "$TEMP_SCRIPT" ]; then
    echo "Failed to extract loop from $SCRIPT_FILE"
    exit 1
fi

# Mock sudo and iptables
# We want to verify that `iptables -t mangle -A HYST1 -j RETURN` is called.
# We'll create a function `sudo` that checks arguments.

cat << 'EOF' > test_wrapper.sh
#!/bin/bash
MAPPING_FILE="test_mapping.txt"

# Mock sudo
sudo() {
    # check if command is iptables
    if [[ "$1" == "iptables" ]]; then
        echo "iptables called with: ${@:2}"
    else
        # Allow other sudo commands or ignore
        :
    fi
}

# Source the extracted script
source ./temp_test_loop.sh

EOF

chmod +x test_wrapper.sh

# Run the wrapper
OUTPUT=$(./test_wrapper.sh)

# Check for the specific rule
if echo "$OUTPUT" | grep -q "iptables called with: -t mangle -A HYST1 -j RETURN"; then
    echo "SUCCESS: Found usage of RETURN rule in iptables commands."
else
    echo "FAILURE: Did not find usage of RETURN rule in iptables commands."
    echo "Output was:"
    echo "$OUTPUT"
    exit 1
fi

# Cleanup
rm "$TEMP_SCRIPT" "$MAPPING_FILE" "test_wrapper.sh"
