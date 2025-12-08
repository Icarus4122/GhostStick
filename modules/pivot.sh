#!/bin/bash
# GhostCTL Pivot Module

# shellcheck source=/dev/null

mod_status() {
    info "Pivot Engine Status"
    
    local CFG="$GS/pivot.env"
    
    if [ -f "$CFG" ]; then
        source "$CFG"
        echo "Enabled: ${PIVOT_ENABLE:-false}"
        echo "Upstream: ${PIVOT_HOST:-not configured}"
        echo "Port: ${PIVOT_PORT:-22}"
        echo "User: ${PIVOT_USER:-operator}"
        echo "Mode: ${AUTO_MODE:-auto}"
        echo
    else
        warn "Pivot not configured"
        echo
    fi
    
    info "Active Tunnels:"
    
    if systemctl is-active --quiet pivot-autossh.service; then
        ok "AutoSSH reverse tunnel active"
    else
        echo "  AutoSSH: inactive"
    fi
    
    if systemctl is-active --quiet pivot-chisel.service; then
        ok "Chisel reverse tunnel active"
    else
        echo "  Chisel: inactive"
    fi
    
    if systemctl is-active --quiet wg-quick@wg0; then
        ok "WireGuard active"
    else
        echo "  WireGuard: inactive"
    fi
}

mod_enable() {
    mkdir -p "$GS"
    
    cat > "$GS/pivot.env" <<EOF
PIVOT_ENABLE="true"
PIVOT_HOST="${1:-}"
PIVOT_PORT="${2:-22}"
PIVOT_USER="${3:-operator}"
AUTO_MODE="auto"
STEALTH_LEVEL="medium"
EOF
    
    ok "Pivot enabled. Configure with: ghostctl pivot config"
}

mod_disable() {
    echo 'PIVOT_ENABLE="false"' > "$GS/pivot.env"
    
    systemctl stop pivot-autossh.service 2>/dev/null
    systemctl stop pivot-chisel.service 2>/dev/null
    
    ok "Pivot disabled"
}

mod_config() {
    "${EDITOR:-nano}" "$GS/pivot.env"
}

mod_restart() {
    local SERVICE="${1:-all}"
    
    case "$SERVICE" in
        autossh)
            systemctl restart pivot-autossh.service
            ok "AutoSSH restarted"
            ;;
        chisel)
            systemctl restart pivot-chisel.service
            ok "Chisel restarted"
            ;;
        wireguard|wg)
            systemctl restart wg-quick@wg0
            ok "WireGuard restarted"
            ;;
        all)
            systemctl restart pivot-autossh.service 2>/dev/null
            systemctl restart pivot-chisel.service 2>/dev/null
            systemctl restart wg-quick@wg0 2>/dev/null
            ok "All pivot services restarted"
            ;;
        *)
            err "Unknown service: $SERVICE"
            exit 1
            ;;
    esac
}

mod_logs() {
    local SERVICE="${1:-autossh}"
    
    case "$SERVICE" in
        autossh)
            journalctl -u pivot-autossh.service -n 50 --no-pager
            ;;
        chisel)
            journalctl -u pivot-chisel.service -n 50 --no-pager
            ;;
        wireguard|wg)
            journalctl -u wg-quick@wg0 -n 50 --no-pager
            ;;
        *)
            err "Unknown service: $SERVICE"
            exit 1
            ;;
    esac
}

mod_test() {
    local HOST="${1:-}"
    
    if [ -z "$HOST" ]; then
        if [ -f "$GS/pivot.env" ]; then
            # shellcheck source=/dev/null
            source "$GS/pivot.env"
            HOST="$PIVOT_HOST"
        fi
    fi
    
    if [ -z "$HOST" ]; then
        err "No host specified"
        exit 1
    fi
    
    info "Testing connectivity to: $HOST"
    
    if timeout 5 bash -c "echo >/dev/tcp/$HOST/22" 2>/dev/null; then
        ok "SSH port reachable"
    else
        warn "Cannot reach SSH port"
    fi
    
    if ping -c 3 "$HOST" >/dev/null 2>&1; then
        ok "Host responds to ping"
    else
        warn "Host does not respond to ping"
    fi
}
