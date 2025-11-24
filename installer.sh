#!/bin/bash
set -euo pipefail

PROJECT_NAME="GhostStick Zero"
MODULE_DIR="./modules"
STATE_DIR="/opt/ghoststick/state"

echo "---------------------------------------------"
echo "[Installer] Starting $PROJECT_NAME build..."
echo "---------------------------------------------"

mkdir -p "$STATE_DIR"

###############################################################
# 0. PRECHECKS
###############################################################
if [[ $EUID -ne 0 ]]; then
    echo "[-] ERROR: Installer must run as root."
    exit 1
fi

if [ ! -d "$MODULE_DIR" ]; then
    echo "[-] ERROR: modules/ directory missing!"
    exit 1
fi

###############################################################
# 1. DRY RUN MODE (Optional)
###############################################################
DRYRUN="${DRYRUN:-false}"

if [ "$DRYRUN" = "true" ]; then
    echo "[Installer] DRY RUN MODE ENABLED — modules will not execute."
fi

###############################################################
# 2. OPERATOR OVERRIDE (Run only specific modules)
###############################################################
if [ -f "./run.only" ]; then
    echo "[Installer] Operator override: run.only found."

    # Safe grep — no error if empty, no subshell cat
    mapfile -t MODULE_LIST < <(grep '^[0-9]' ./run.only 2>/dev/null | sort)

    if [ "${#MODULE_LIST[@]}" -eq 0 ]; then
        echo "[-] run.only file is empty or invalid."
        exit 1
    fi

    echo "[Installer] Restricted module list:"
    printf ' - %s\n' "${MODULE_LIST[@]}"
else
    # Default: load all modules
    mapfile -t MODULE_LIST < <(
        find "$MODULE_DIR" -maxdepth 1 -type f -printf '%f\n' |
        sort |
        grep '^[0-9]'
    )
fi

###############################################################
# 3. EXECUTION LOOP WITH LOG + STATE MACHINE
###############################################################
INSTALL_LOG="/opt/ghoststick/install.log"
touch "$INSTALL_LOG"

for module in "${MODULE_LIST[@]}"; do
    MODULE_PATH="${MODULE_DIR}/${module}"

    if [ ! -f "$MODULE_PATH" ]; then
        echo "[Installer] Skipping missing module: $module"
        continue
    fi

    STATE_FILE="$STATE_DIR/${module}.done"

    if [ -f "$STATE_FILE" ]; then
        echo "[Installer] SKIP (already done): $module"
        continue
    fi

    echo "[Installer] Running module: $module"
    echo "$(date +"%F %T") — RUN $module" >> "$INSTALL_LOG"

    if [ "$DRYRUN" = "false" ]; then
        if ! bash "$MODULE_PATH"; then
            echo ""
            echo "---------------------------------------------"
            echo " ERROR in module: $module"
            echo " Installation aborted."
            echo "---------------------------------------------"
            exit 1
        fi
    fi

    touch "$STATE_FILE"
done

###############################################################
# 4. FINAL BANNER
###############################################################
echo ""
echo "==============================================="
echo "   $PROJECT_NAME installation complete!"
echo "   Reboot to activate composite USB mode."
echo "==============================================="
echo ""
