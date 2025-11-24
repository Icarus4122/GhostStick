#!/usr/bin/env bash
set -euo pipefail

###############################################
# Colors
###############################################
RED="\e[31m"
YLW="\e[33m"
CYN="\e[36m"
RST="\e[0m"

log()   { echo -e "${CYN}[00]${RST} $1"; }
warn()  { echo -e "${YLW}[-]${RST} $1"; }
fail()  { echo -e "${RED}[!] $1${RST}"; exit 1; }

log "Preflight checks starting..."

###############################################
# 0. ROOT CHECK
###############################################
if [[ $EUID -ne 0 ]]; then
    fail "Must run as root."
fi

###############################################
# 1. Dependency Checks
###############################################
log "Updating package lists..."

if ! apt-get update -y >/dev/null 2>&1; then
    warn "apt update failed — retrying with safe flags..."
    apt-get update --allow-releaseinfo-change -y || fail "APT update failed."
fi

PKGS=(jq)
for p in "${PKGS[@]}"; do
    if ! dpkg -s "$p" >/dev/null 2>&1; then
        log "Installing $p..."
        apt-get install -y "$p" >/dev/null 2>&1 || fail "Package install failed."
    fi
done

###############################################
# 2. Directory Preparation
###############################################
GS_DIR="/opt/ghoststick"
STATE="$GS_DIR/state"
OVERRIDE="$GS_DIR/override"
LOGFILE="$GS_DIR/install.log"

log "Preparing directories..."
mkdir -p "$GS_DIR" "$STATE" "$OVERRIDE"

touch "$LOGFILE"

###############################################
# 3. Resume / Fresh Install Detection
###############################################
if [ -f "$STATE/preflight.done" ]; then
    log "Preflight previously completed — resuming."
    MODE="resume"
else
    log "Fresh initialization detected."
    MODE="fresh"
fi

###############################################
# 4. System Fingerprint Collection
###############################################
ARCH=$(uname -m || echo "unknown")
OS=$(grep -oP '(?<=VERSION_CODENAME=).*' /etc/os-release || echo "unknown")
KERNEL=$(uname -r || echo "unknown")

USB_CAPABLE=false
PYTHON_EXISTS=false
HAS_NM=false

modprobe -n libcomposite >/dev/null 2>&1 && USB_CAPABLE=true
[ -d /usr/lib/python3/dist-packages ] && PYTHON_EXISTS=true
command -v nmcli >/dev/null 2>&1 && HAS_NM=true

###############################################
# 5. Save Fingerprint to JSON (validated)
###############################################
log "Writing system fingerprint to state file..."

cat > "$STATE/preflight.json" <<EOF
{
  "arch": "$ARCH",
  "os_codename": "$OS",
  "kernel": "$KERNEL",
  "usb_capable": $USB_CAPABLE,
  "python_available": $PYTHON_EXISTS,
  "networkmanager": $HAS_NM,
  "install_mode": "$MODE"
}
EOF

# Validate JSON
if ! jq empty "$STATE/preflight.json" >/dev/null 2>&1; then
    fail "preflight.json is invalid JSON!"
fi

###############################################
# 6. Operator Override Bootstrap
###############################################
declare -A DEFAULTS=(
    ["wifi.mode"]="auto"
    ["profile.force"]=""
    ["hid.layout"]="us"
    ["usb.mode"]="auto"
)

log "Initializing override configuration..."
for key in "${!DEFAULTS[@]}"; do
    file="$OVERRIDE/$key"
    if [ ! -f "$file" ]; then
        echo "${DEFAULTS[$key]}" > "$file"
    fi
done

###############################################
# 7. Mark Completed
###############################################
touch "$STATE/preflight.done"

log "---------------------------------------------"
log "Preflight Complete • GhostStick Ready"
log "---------------------------------------------"
