#!/bin/bash
# GhostCTL Stealth Module

# shellcheck source=/dev/null

mod_show() {
    info "Stealth Configuration"
    
    local SECENV="$GS/security.env"
    
    if [ -f "$SECENV" ]; then
        source "$SECENV"
        echo "Level: ${STEALTH_LEVEL:-medium}"
        echo "Randomize Hostname: ${RANDOMIZE_HOSTNAME:-true}"
        echo "Randomize MAC: ${RANDOMIZE_MAC:-true}"
        echo "Minimize Logs: ${MINIMIZE_LOGS:-true}"
        echo "Disable Services: ${DISABLE_SERVICES:-true}"
        echo "Kernel Hardening: ${KERNEL_HARDENING:-true}"
    else
        warn "Stealth not configured"
    fi
}

mod_set() {
    local LEVEL="$1"
    
    case "$LEVEL" in
        low|medium|high)
            mkdir -p "$GS"
            
            if [ -f "$GS/security.env" ]; then
                sed -i "s/STEALTH_LEVEL=.*/STEALTH_LEVEL=\"$LEVEL\"/" "$GS/security.env"
            else
                echo "STEALTH_LEVEL=\"$LEVEL\"" > "$GS/security.env"
            fi
            
            ok "Stealth level set to: $LEVEL"
            warn "Run 'ghostctl stealth apply' to activate"
            ;;
        *)
            err "Invalid level. Choose: low, medium, high"
            exit 1
            ;;
    esac
}

mod_apply() {
    if ! confirm "Apply stealth hardening"; then
        warn "Cancelled."
        exit 0
    fi
    
    bash /opt/ghoststick/modules/90-hardening.sh
    ok "Stealth hardening applied"
}

mod_config() {
    "${EDITOR:-nano}" "$GS/security.env"
}
