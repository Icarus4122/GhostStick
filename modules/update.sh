#!/bin/bash
# GhostCTL Update Module

# shellcheck source=/dev/null

mod_status() {
    info "Update System Status"
    
    local UPCFG="$GS/update.env"
    
    if [ -f "$UPCFG" ]; then
        source "$UPCFG"
        echo "Auto Update: ${AUTO_UPDATE:-weekly}"
        echo "Allow Updates: ${ALLOW_UPDATES:-auto}"
        echo "Package Mode: ${PKG_MODE:-stable}"
        echo "Stealth Level: ${STEALTH_LEVEL:-medium}"
    else
        warn "Update system not configured"
    fi
    
    echo
    info "Last update check:"
    stat -c %y /var/lib/apt/periodic/update-success-stamp 2>/dev/null || echo "Never"
}

mod_run() {
    if ! confirm "Run system update now"; then
        warn "Cancelled."
        exit 0
    fi
    
    /usr/local/bin/ghoststick-update.sh
}

mod_config() {
    "${EDITOR:-nano}" "$GS/update.env"
}

mod_enable() {
    sed -i 's/ALLOW_UPDATES=.*/ALLOW_UPDATES="auto"/' "$GS/update.env" 2>/dev/null || \
        echo 'ALLOW_UPDATES="auto"' >> "$GS/update.env"
    ok "Updates enabled"
}

mod_disable() {
    sed -i 's/ALLOW_UPDATES=.*/ALLOW_UPDATES="block"/' "$GS/update.env" 2>/dev/null || \
        echo 'ALLOW_UPDATES="block"' >> "$GS/update.env"
    ok "Updates disabled"
}

mod_schedule() {
    local FREQ="$1"
    
    case "$FREQ" in
        daily|weekly|off)
            sed -i "s/AUTO_UPDATE=.*/AUTO_UPDATE=\"$FREQ\"/" "$GS/update.env" 2>/dev/null || \
                echo "AUTO_UPDATE=\"$FREQ\"" >> "$GS/update.env"
            ok "Update schedule set to: $FREQ"
            warn "Rerun module: bash /opt/ghoststick/modules/85-updater.sh"
            ;;
        *)
            err "Invalid frequency. Choose: daily, weekly, off"
            exit 1
            ;;
    esac
}
