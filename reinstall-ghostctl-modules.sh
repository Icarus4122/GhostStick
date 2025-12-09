#!/bin/bash
# Reinstall GhostCTL modules to /opt/ghoststick/modules/

set -e

if [[ $EUID -ne 0 ]]; then
    echo "Error: Must run as root"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/modules"
TARGET_DIR="/opt/ghoststick/modules"

echo "================================================"
echo "    GhostCTL Module Reinstaller"
echo "================================================"
echo ""
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
echo ""

# Create target directory
mkdir -p "$TARGET_DIR"

# Copy all GhostCTL modules
COPIED=0
FAILED=0

for mod in wifi hid exfil pivot profile stealth update system hardening seal diag menu; do
    if [ -f "$SOURCE_DIR/${mod}.sh" ]; then
        if cp -v "$SOURCE_DIR/${mod}.sh" "$TARGET_DIR/"; then
            chmod +x "$TARGET_DIR/${mod}.sh"
            COPIED=$((COPIED + 1))
        else
            echo "Failed to copy: ${mod}.sh"
            FAILED=$((FAILED + 1))
        fi
    else
        echo "Not found: $SOURCE_DIR/${mod}.sh"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "================================================"
echo "Results: $COPIED copied, $FAILED failed/missing"
echo "================================================"
echo ""

if [ $COPIED -gt 0 ]; then
    echo "Modules installed in: $TARGET_DIR"
    echo "Test with: ghostctl wifi status"
    echo ""
fi

if [ $FAILED -gt 0 ]; then
    echo "Some modules are missing from $SOURCE_DIR"
    echo "Make sure you run this from the GhostStick repository directory"
    exit 1
fi

exit 0
