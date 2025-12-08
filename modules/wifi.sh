#!/bin/bash
# GhostCTL WiFi Module

mod_status() {
    info "WiFi Status"
    echo "Mode: $(cat "$GS/wifi.mode" 2>/dev/null || echo 'auto')"
    echo "Interface: wlan0"
    ip addr show wlan0 2>/dev/null || echo "wlan0 not found"
    echo
    echo "Current Connection:"
    iwgetid -r 2>/dev/null || echo "Not connected"
}

mod_set() {
    local MODE="$1"
    case "$MODE" in
        auto|home|roam|off)
            echo "$MODE" > "$GS/wifi.mode"
            ok "WiFi mode set to: $MODE"
            warn "Run 'ghostctl wifi reload' to apply."
            ;;
        *)
            err "Invalid mode. Use: auto, home, roam, or off"
            exit 1
            ;;
    esac
}

mod_add() {
    local SSID="$1"
    local PSK="$2"

    if [[ -z "$SSID" || -z "$PSK" ]]; then
        err "Usage: ghostctl wifi add <ssid> <passphrase>"
        exit 1
    fi

    mkdir -p "$GS/wifi.home"
    echo "$PSK" > "$GS/wifi.home/${SSID}.psk"
    ok "Network '$SSID' added to home list."
}

mod_remove() {
    local SSID="$1"

    if [[ -z "$SSID" ]]; then
        err "Usage: ghostctl wifi remove <ssid>"
        exit 1
    fi

    rm -f "$GS/wifi.home/${SSID}.psk"
    ok "Network '$SSID' removed."
}

mod_list() {
    info "Saved Networks:"
    if [ -d "$GS/wifi.home" ]; then
        for f in "$GS/wifi.home"/*.psk; do
            [ -f "$f" ] || continue
            basename "$f" .psk
        done
    else
        echo "None"
    fi
}

mod_reload() {
    if ! confirm "Reload WiFi configuration"; then
        warn "Cancelled."
        exit 0
    fi

    bash /opt/ghoststick/modules/40-wifi.sh
    ok "WiFi configuration reloaded."
}

mod_scan() {
    info "Scanning for WiFi networks..."
    iwlist wlan0 scan 2>/dev/null | grep -E "ESSID|Quality" | head -20
}
