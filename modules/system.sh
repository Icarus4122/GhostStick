#!/bin/bash
# GhostCTL System Module

mod_reboot() {
    if ! confirm "Reboot system"; then
        warn "Cancelled."
        exit 0
    fi
    
    ok "Rebooting..."
    sleep 2
    reboot
}

mod_shutdown() {
    if ! confirm "Shutdown system"; then
        warn "Cancelled."
        exit 0
    fi
    
    ok "Shutting down..."
    sleep 2
    poweroff
}

mod_services() {
    info "GhostStick Services:"
    echo
    
    systemctl is-active ghoststick-gadget && echo -e "${GREEN}✓${RESET} USB Gadget" || echo -e "${RED}✗${RESET} USB Gadget"
    systemctl is-active dnsmasq && echo -e "${GREEN}✓${RESET} DHCP Server" || echo -e "${RED}✗${RESET} DHCP Server"
    systemctl is-active pivot-autossh && echo -e "${GREEN}✓${RESET} AutoSSH" || echo -e "${RED}✗${RESET} AutoSSH"
    systemctl is-active pivot-chisel && echo -e "${GREEN}✓${RESET} Chisel" || echo -e "${RED}✗${RESET} Chisel"
    systemctl is-active wg-quick@wg0 && echo -e "${GREEN}✓${RESET} WireGuard" || echo -e "${RED}✗${RESET} WireGuard"
}

mod_logs() {
    local SERVICE="${1:-all}"
    
    if [ "$SERVICE" = "all" ]; then
        journalctl -xe --no-pager | tail -50
    else
        journalctl -u "$SERVICE" -n 50 --no-pager
    fi
}

mod_info() {
    info "System Information"
    echo
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Uptime: $(uptime -p)"
    echo
    echo "Memory:"
    free -h | grep -E "Mem|Swap"
    echo
    echo "Disk:"
    df -h / | tail -1
    echo
    echo "USB Network:"
    ip addr show usb0 2>/dev/null || echo "usb0 not configured"
}
