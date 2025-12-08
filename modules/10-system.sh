#!/usr/bin/env bash
set -euo pipefail

echo "[10] System — Adaptive Bootstrap Engine"

GS="/opt/ghoststick"
STATE="$GS/state"
LOG="$GS/system.log"
mkdir -p "$STATE"

# Quiet helper
quiet() { "$@" >/dev/null 2>&1; }

###############################################
# 0. RESUME-SAFE STATE MACHINE
###############################################
if [ -f "$STATE/system.done" ]; then
    echo "[10] System stage previously completed."
    exit 0
fi
touch "$STATE/system.start"

###############################################
# 1. LOAD PREFLIGHT FINGERPRINT
###############################################
PRE="$STATE/preflight.json"

if ! jq empty "$PRE" >/dev/null 2>&1; then
    echo "[!] ERROR: preflight.json is corrupted or unreadable."
    exit 1
fi

ARCH=$(jq -r '.arch' "$PRE")
OS_CODENAME=$(jq -r '.os_codename' "$PRE")
KERNEL=$(jq -r '.kernel' "$PRE")
USB_CAPABLE=$(jq -r '.usb_capable' "$PRE")
PY_AVAILABLE=$(jq -r '.python_available' "$PRE")
HAS_NM=$(jq -r '.networkmanager' "$PRE")

###############################################
# 2. BASE SYSTEM UPDATE 
###############################################
quiet apt-get update || {
    echo "[!] apt update failed. Retrying..."
    quiet apt-get update --allow-releaseinfo-change
}

quiet apt-get upgrade -y || {
    echo "[!] apt upgrade issue — attempting dpkg repair."
    quiet dpkg --configure -a
    quiet apt-get -f install -y
}

###############################################
# 3. SMART INSTALLER (ARCH + OS AWARE)
###############################################
install_pkg() {

    local pkg="$1"

    # Try normal install first
    if quiet apt-get install -y "$pkg" --no-install-recommends; then
        return 0
    fi

    # Search exact match
    ALT=$(apt-cache search "^${pkg}$" | awk '{print $1}' | head -n1)
    if [ -n "${ALT:-}" ] && quiet apt-get install -y "$ALT" --no-install-recommends; then
        return 0
    fi

    # Loose match fallback
    ALT2=$(apt-cache search "$pkg" | awk '{print $1}' | grep -E "^${pkg}(-.*)?$" | head -n1)
    if [ -n "${ALT2:-}" ] && quiet apt-get install -y "$ALT2" --no-install-recommends; then
        return 0
    fi

    # Attempt repair + retry
    quiet apt-get -f install -y
    quiet dpkg --configure -a
    quiet apt-get install -y "$pkg" --no-install-recommends || {
        echo "[!] Failed to install: $pkg" | tee -a "$LOG"
    }
}

###############################################
# 4. CORE PACKAGES (ADAPTIVE)
###############################################
CORE_PKGS=(
    git
    python3 python3-dev python3-pip python3-venv python3-setuptools python3-wheel
    ruby-full
    dnsmasq
    autossh
    jq
    curl
    wget
    pipx
    cryptsetup-bin
    parted
    dos2unix
    pv
    gcc make build-essential
    sudo
)

# ARM-specific additions
if [[ "$ARCH" =~ arm ]]; then
    CORE_PKGS+=(wireguard-tools)
else
    CORE_PKGS+=(wireguard)
fi

for pkg in "${CORE_PKGS[@]}"; do
    install_pkg "$pkg"
done

###############################################
# 5. PYTHON SUBSYSTEM — SANDBOX OR SYSTEM
###############################################
if [ "$PY_AVAILABLE" = "true" ]; then

    if quiet python3 -m venv "$GS/pysbx"; then
        quiet "$GS/pysbx/bin/pip" install --upgrade pip wheel setuptools
        echo "$GS/pysbx/bin/python" > "$STATE/python.exec"
    else
        echo "[!] Python venv creation failed. Falling back to system python."
        echo "export PIP_BREAK_SYSTEM_PACKAGES=1" > /etc/profile.d/ghost-pip.sh
        echo "python3" > "$STATE/python.exec"
    fi

else
    echo "export PIP_BREAK_SYSTEM_PACKAGES=1" > /etc/profile.d/ghost-pip.sh
    echo "python3" > "$STATE/python.exec"
fi

###############################################
# 6. NETWORK STACK FLAG EXPORT
###############################################
if [ "$HAS_NM" = "true" ]; then
    echo "networkmanager" > "$STATE/net.stacktype"
else
    echo "legacy" > "$STATE/net.stacktype"
fi

###############################################
# 7. USB GADGET CAPABILITY EXPORT
###############################################
if [ "$USB_CAPABLE" = "true" ]; then
    echo "enabled" > "$STATE/usb.capability"
else
    echo "disabled" > "$STATE/usb.capability"
fi

###############################################
# 8. SYSTEM PROFILE SNAPSHOT
###############################################
cat > "$GS/system.profile" <<EOF
ARCH=${ARCH:-unknown}
OS=${OS_CODENAME:-unknown}
KERNEL=${KERNEL:-unknown}
USB_CAPABLE=${USB_CAPABLE}
PY_SANDBOX=${PY_AVAILABLE}
NET_STACK_MANAGER=${HAS_NM}
EOF

###############################################
# 9. MARK COMPLETED
###############################################
touch "$STATE/system.done"

echo "---------------------------------------------"
echo "[10] System stage complete"
echo "---------------------------------------------"
