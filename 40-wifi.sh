#!/usr/bin/env bash
echo "[40] WiFi — StealthRoam Engine (Non-Disruptive Mode)"

set -euo pipefail

GS="/opt/ghoststick"
STATE="$GS/state"
mkdir -p "$STATE"

WCONF="/etc/wpa_supplicant/wpa_supplicant.conf"
HOME_DIR="$GS/wifi.home"
MODE_FILE="$GS/wifi.mode"

###############################################
# 0. RESUME-SAFE STATE MACHINE
###############################################
if [ -f "$STATE/wifi.done" ]; then
    echo "[40] WiFi already configured."
    exit 0
fi
touch "$STATE/wifi.start"

mkdir -p "$HOME_DIR"

###############################################
# 1. DETECT IF SSH IS RUNNING THROUGH WLAN0
###############################################
WIFI_ACTIVE=false
SSH_IFACE=""

# Determine the interface used for SSH
SSH_IFACE=$(ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {print $5; exit}')

if [[ "$SSH_IFACE" == "wlan0" ]]; then
    WIFI_ACTIVE=true
    echo "[40] SSH over wlan0 detected — preventing restarts."
fi

###############################################
# 2. DETERMINE MODE (auto | home | roam | off)
###############################################
if [ -f "$MODE_FILE" ]; then
    MODE=$(tr -d ' \t' < "$MODE_FILE")
else
    MODE="auto"
    echo "auto" > "$MODE_FILE"
fi

echo "[40] WiFi mode: $MODE"

###############################################
# 3. NETWORKMANAGER STEALTH MAC RANDOMIZATION
###############################################
mkdir -p /etc/NetworkManager/conf.d

cat > /etc/NetworkManager/conf.d/wifi-stealth.conf <<EOF
[connection]
wifi.cloned-mac-address=random

[device]
wifi.scan-rand-mac-address=yes
wifi.disable-mac-randomization=no
EOF

###############################################
# 4. DETERMINE IF iwd IS ACTIVE (Pi OS newer)
###############################################
if systemctl is-active --quiet iwd; then
    echo "[40] iwd detected — disabling (wpa_supplicant required)."
    systemctl stop iwd || true
    systemctl disable iwd || true
fi

###############################################
# 5. BASE WPA_SUPPLICANT HEADER
###############################################
cat > "$WCONF" <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US
EOF

###############################################
# 6. MODE HANDLING
###############################################
case "$MODE" in

off)
    echo "[40] WiFi disabled (no networks added)."
    ;;

roam)
    echo "[40] Roam mode — open networks only (aggressive roaming)."

cat >> "$WCONF" <<EOF

ap_scan=0

network={
    key_mgmt=NONE
    priority=15
}
EOF
    ;;

home)
    echo "[40] Home-only mode."

    echo "ap_scan=1" >> "$WCONF"

    for f in "$HOME_DIR"/*.psk; do
        [ -f "$f" ] || continue

        SSID=$(basename "$f" .psk)
        PSK=$(cat "$f")

cat >> "$WCONF" <<EOF

network={
    ssid="$(printf '%s' "$SSID")"
    psk="$(printf '%s' "$PSK")"
    key_mgmt=WPA-PSK
    priority=20
}
EOF
    done
    ;;

auto)
    echo "[40] Auto-Stealth mode."

    echo "ap_scan=1" >> "$WCONF"

    # Open networks first
cat >> "$WCONF" <<EOF

network={
    key_mgmt=NONE
    priority=5
}
EOF

    # Add home-secured networks lower priority
    for f in "$HOME_DIR"/*.psk; do
        [ -f "$f" ] || continue

        SSID=$(basename "$f" .psk)
        PSK=$(cat "$f")

cat >> "$WCONF" <<EOF

network={
    ssid="$(printf '%s' "$SSID")"
    psk="$(printf '%s' "$PSK")"
    key_mgmt=WPA-PSK
    priority=1
}
EOF
    done
    ;;

*)
    echo "[40] Unknown mode '$MODE' — using auto."
    ;;
esac

###############################################
# 7. SERVICE ACTIVATION — ONLY IF SAFE
###############################################
if ! $WIFI_ACTIVE; then
    echo "[40] Applying WiFi config..."

    systemctl restart wpa_supplicant 2>/dev/null || true
    systemctl restart NetworkManager 2>/dev/null || true

    echo "[40] WiFi services restarted safely."
else
    echo "[40] Restart skipped due to active SSH on wlan0."
fi

###############################################
# 8. FINISH
###############################################
touch "$STATE/wifi.done"
echo "[40] WiFi StealthRoam configuration staged."
