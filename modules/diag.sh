#!/bin/bash
# GhostCTL Diagnostics Module

mod_preflight() {
    info "Running Preflight Diagnostics"
    echo
    
    local PREFLIGHT="$STATE/preflight.json"
    
    if [ -f "$PREFLIGHT" ]; then
        jq . "$PREFLIGHT" 2>/dev/null || cat "$PREFLIGHT"
    else
        warn "Preflight data not found"
    fi
}

mod_usb() {
    info "USB Gadget Diagnostics"
    echo
    
    if [ -d "/sys/kernel/config/usb_gadget/ghoststick" ]; then
        ok "USB gadget configured"
        echo
        echo "Gadget Details:"
        cat /sys/kernel/config/usb_gadget/ghoststick/idVendor 2>/dev/null && echo " (Vendor ID)"
        cat /sys/kernel/config/usb_gadget/ghoststick/idProduct 2>/dev/null && echo " (Product ID)"
        cat /sys/kernel/config/usb_gadget/ghoststick/UDC 2>/dev/null && echo " (UDC Controller)"
    else
        warn "USB gadget not configured"
    fi
    
    echo
    info "USB Interface usb0:"
    ip addr show usb0 2>/dev/null || warn "usb0 not found"
    
    echo
    info "HID Device:"
    if [ -e "/dev/hidg0" ]; then
        ok "/dev/hidg0 exists"
        ls -la /dev/hidg0
    else
        warn "/dev/hidg0 not found"
    fi
}

mod_network() {
    info "Network Diagnostics"
    echo
    
    echo "Network Stack: $(cat "$STATE/net.stack" 2>/dev/null || echo 'unknown')"
    echo
    
    info "Interfaces:"
    ip -br addr
    echo
    
    info "Routes:"
    ip route
    echo
    
    info "DNS:"
    grep nameserver /etc/resolv.conf 2>/dev/null || echo "None"
    echo
    
    info "DHCP Leases (usb0):"
    cat /var/lib/misc/dnsmasq.leases 2>/dev/null || echo "No leases"
}

mod_upstream() {
    info "Upstream Connectivity Test"
    echo
    
    if ping -c 3 1.1.1.1 >/dev/null 2>&1; then
        ok "Internet reachable (1.1.1.1)"
    else
        warn "No internet connectivity"
    fi
    
    if [ -f "$GS/upstream.json" ]; then
        echo
        info "Upstream State:"
        jq . "$GS/upstream.json" 2>/dev/null || cat "$GS/upstream.json"
    fi
}

mod_modules() {
    info "Module Installation Status"
    echo
    
    for module in 00-preflight 10-system 20-usb-gadget 30-networking 40-wifi \
                  50-tools-core 60-hid 70-exfil 80-pivot 85-updater \
                  90-hardening 95-ghostctl 99-final; do
        if [ -f "$STATE/${module}.done" ]; then
            echo -e "${GREEN}✓${RESET} ${module}"
        else
            echo -e "${RED}✗${RESET} ${module}"
        fi
    done
}

mod_full() {
    mod_preflight
    echo
    mod_usb
    echo
    mod_network
    echo
    mod_upstream
    echo
    mod_modules
}

mod_logs() {
    if [ -f "$GS/install.log" ]; then
        tail -50 "$GS/install.log"
    else
        warn "No installation log found"
    fi
}
