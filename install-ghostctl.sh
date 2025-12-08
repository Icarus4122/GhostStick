#!/bin/bash
# GhostStick - Install GhostCTL command globally

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: Must run as root"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GHOSTCTL_SOURCE="$SCRIPT_DIR/modules/95-ghostctl.sh"

if [ ! -f "$GHOSTCTL_SOURCE" ]; then
    echo "Error: 95-ghostctl.sh not found in modules/"
    exit 1
fi

# Install to /usr/local/bin
cp "$GHOSTCTL_SOURCE" /usr/local/bin/ghostctl
chmod +x /usr/local/bin/ghostctl

echo "✓ GhostCTL installed to /usr/local/bin/ghostctl"
echo ""
echo "Usage: ghostctl <module> <action>"
echo "   or: ghostctl menu (interactive)"
echo "   or: ghostctl help"
