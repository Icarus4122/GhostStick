#!/bin/bash
# GhostStick - Verify Installation
# Run this to check if all components are properly installed

set -euo pipefail

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

ok()   { echo -e "${GREEN}✓${RESET} $1"; }
warn() { echo -e "${YELLOW}⚠${RESET} $1"; }
fail() { echo -e "${RED}✗${RESET} $1"; }
info() { echo -e "${CYAN}[i]${RESET} $1"; }

echo "================================================"
echo "  GhostStick Installation Verification"
echo "================================================"
echo

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    fail "This script must run on Linux"
    exit 1
fi

# Check installation directory
info "Checking installation directory..."
if [ -d "/opt/ghoststick" ]; then
    ok "Installation directory exists"
else
    fail "Installation directory not found: /opt/ghoststick"
    exit 1
fi

# Check state directory
if [ -d "/opt/ghoststick/state" ]; then
    ok "State directory exists"
else
    warn "State directory not found"
fi

# Check completed modules
info "Checking module completion status..."
MODULES=(
    "00-preflight"
    "10-system"
    "20-usb-gadget"
    "30-networking"
    "40-wifi"
    "50-tools-core"
    "60-hid"
    "70-exfil"
    "80-pivot"
    "85-updater"
    "90-hardening"
    "95-ghostctl"
    "99-final"
)

COMPLETED=0
TOTAL=${#MODULES[@]}

for mod in "${MODULES[@]}"; do
    if [ -f "/opt/ghoststick/state/${mod}.done" ]; then
        ok "$mod"
        ((COMPLETED++))
    else
        fail "$mod (not completed)"
    fi
done

echo
echo "Modules: $COMPLETED/$TOTAL completed"
echo

# Check USB gadget
info "Checking USB gadget..."
if [ -d "/sys/kernel/config/usb_gadget/ghoststick" ]; then
    ok "USB gadget configured"
    
    if [ -f "/sys/kernel/config/usb_gadget/ghoststick/UDC" ]; then
        UDC=$(cat /sys/kernel/config/usb_gadget/ghoststick/UDC)
        if [ -n "$UDC" ]; then
            ok "USB gadget active (UDC: $UDC)"
        else
            warn "USB gadget not activated"
        fi
    fi
else
    warn "USB gadget not configured"
fi

# Check usb0 interface
info "Checking USB network interface..."
if ip link show usb0 &>/dev/null; then
    ok "usb0 interface exists"
    
    if ip addr show usb0 | grep -q "172.16.1.1"; then
        ok "usb0 has correct IP (172.16.1.1)"
    else
        warn "usb0 IP not configured correctly"
    fi
else
    warn "usb0 interface not found"
fi

# Check HID device
info "Checking HID device..."
if [ -e "/dev/hidg0" ]; then
    ok "HID device exists (/dev/hidg0)"
else
    warn "HID device not found (may be disabled by profile)"
fi

# Check services
info "Checking system services..."
SERVICES=(
    "ghoststick-gadget"
    "dnsmasq"
)

for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        ok "$svc (active)"
    else
        warn "$svc (not active)"
    fi
done

# Check ghostctl command
info "Checking GhostCTL..."
if command -v ghostctl &>/dev/null; then
    ok "ghostctl command available"
else
    warn "ghostctl command not in PATH"
fi

# Check GhostCTL modules
if [ -d "/opt/ghoststick/modules" ]; then
    MODCOUNT=$(find /opt/ghoststick/modules -name "*.sh" -not -name "[0-9]*" | wc -l)
    if [ "$MODCOUNT" -gt 0 ]; then
        ok "GhostCTL modules installed ($MODCOUNT modules)"
    else
        warn "No GhostCTL modules found"
    fi
else
    warn "GhostCTL modules directory not found"
fi

# Check profile
info "Checking operational profile..."
if [ -f "/opt/ghoststick/profile.final" ]; then
    PROFILE=$(cat /opt/ghoststick/profile.final)
    ok "Profile: $PROFILE"
else
    warn "Profile not configured"
fi

# Check tools
info "Checking offensive tools..."
TOOLS=(
    "chisel"
    "kerbrute"
)

for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        ok "$tool"
    else
        warn "$tool not found"
    fi
done

# Check Python tools
if command -v impacket-secretsdump &>/dev/null; then
    ok "Impacket installed"
else
    warn "Impacket not found"
fi

if command -v crackmapexec &>/dev/null || command -v cme &>/dev/null; then
    ok "CrackMapExec installed"
else
    warn "CrackMapExec not found"
fi

# Summary
echo
echo "================================================"
if [ "$COMPLETED" -eq "$TOTAL" ]; then
    ok "Installation appears complete!"
else
    warn "Installation incomplete ($COMPLETED/$TOTAL modules)"
fi
echo "================================================"
echo
echo "Next steps:"
echo "  1. Reboot if this is first install: sudo reboot"
echo "  2. Check status: ghostctl diag full"
echo "  3. Configure: ghostctl menu"
echo
