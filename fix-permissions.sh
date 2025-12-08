#!/bin/bash
# GhostStick - Make all scripts executable
# Run this if permissions are lost during git operations

echo "Setting executable permissions on all scripts..."

chmod +x installer.sh

if [ -d "modules" ]; then
    chmod +x modules/*.sh
    echo "✓ Module scripts"
fi

echo "✓ Installer script"
echo "Done! All scripts are now executable."
