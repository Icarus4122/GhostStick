#!/bin/bash
# GhostCTL Hardening Module

mod_status() {
    info "Hardening Status"
    
    if [ -f "$STATE/hardening.done" ]; then
        ok "Hardening applied"
    else
        warn "Hardening not applied"
    fi
    
    echo
    echo "Hostname: $(hostname)"
    echo "SSH Password Auth: $(grep PasswordAuthentication /etc/ssh/sshd_config | grep -v '^#' | awk '{print $2}')"
    echo "IPv4 Forward: $(sysctl net.ipv4.ip_forward | awk '{print $3}')"
    echo "Swap: $(swapon --show | wc -l) devices"
}

mod_apply() {
    if ! confirm "Apply security hardening"; then
        warn "Cancelled."
        exit 0
    fi
    
    bash /opt/ghoststick/modules/90-hardening.sh
    ok "Hardening applied"
}

mod_config() {
    "${EDITOR:-nano}" "$GS/security.env"
}
