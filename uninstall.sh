#!/bin/bash
# GhostStick - Uninstaller
# Removes GhostStick components and optionally wipes configuration

set -euo pipefail

RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
CYAN="\e[36m"
RESET="\e[0m"

warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
info() { echo -e "${CYAN}[i]${RESET} $1"; }
ok()   { echo -e "${GREEN}[✓]${RESET} $1"; }
err()  { echo -e "${RED}[✗]${RESET} $1"; }

if [[ $EUID -ne 0 ]]; then
    err "Must run as root"
    exit 1
fi

echo "================================================"
echo "        GhostStick Uninstaller"
echo "================================================"
echo
warn "This will remove GhostStick from your system"
echo
echo "Options:"
echo "  1) Remove services only (keep data)"
echo "  2) Full uninstall (keep /opt/ghoststick)"
echo "  3) Complete removal (DELETE ALL DATA)"
echo "  4) Cancel"
echo
read -r -p "Select option [1-4]: " OPTION

case "$OPTION" in
    1)
        info "Removing services only..."
        
        # Stop and disable services
        systemctl stop ghoststick-gadget 2>/dev/null || true
        systemctl disable ghoststick-gadget 2>/dev/null || true
        systemctl stop pivot-autossh 2>/dev/null || true
        systemctl disable pivot-autossh 2>/dev/null || true
        systemctl stop pivot-chisel 2>/dev/null || true
        systemctl disable pivot-chisel 2>/dev/null || true
        
        # Remove service files
        rm -f /etc/systemd/system/ghoststick-gadget.service
        rm -f /etc/systemd/system/pivot-autossh.service
        rm -f /etc/systemd/system/pivot-chisel.service
        
        systemctl daemon-reload
        
        ok "Services removed"
        info "Configuration and data preserved in /opt/ghoststick"
        ;;
        
    2)
        info "Performing full uninstall..."
        
        # Stop and disable services
        systemctl stop ghoststick-gadget 2>/dev/null || true
        systemctl disable ghoststick-gadget 2>/dev/null || true
        systemctl stop pivot-autossh 2>/dev/null || true
        systemctl disable pivot-autossh 2>/dev/null || true
        systemctl stop pivot-chisel 2>/dev/null || true
        systemctl disable pivot-chisel 2>/dev/null || true
        
        # Remove service files
        rm -f /etc/systemd/system/ghoststick-gadget.service
        rm -f /etc/systemd/system/pivot-autossh.service
        rm -f /etc/systemd/system/pivot-chisel.service
        
        # Remove scripts
        rm -f /usr/local/bin/ghoststick-gadget.sh
        rm -f /usr/local/bin/ghoststick-update.sh
        rm -f /usr/local/bin/ghost-hid-send
        rm -f /usr/local/bin/ghostctl
        
        # Remove configurations
        rm -f /etc/dnsmasq.d/usb0.conf
        rm -f /etc/network/interfaces.d/usb0*
        rm -f /etc/systemd/network/usb0.network
        rm -f /etc/NetworkManager/conf.d/wifi-stealth.conf
        rm -f /etc/sysctl.d/99-usb0-ipv6.conf
        rm -f /etc/profile.d/ghost-pip.sh
        rm -f /etc/profile.d/ghoststick-history.sh
        rm -f /etc/ghoststick-banner
        rm -f /etc/cron.d/ghoststick-update
        
        # Clean up USB gadget
        if [ -d "/sys/kernel/config/usb_gadget/ghoststick" ]; then
            echo "" > /sys/kernel/config/usb_gadget/ghoststick/UDC 2>/dev/null || true
            rm -rf /sys/kernel/config/usb_gadget/ghoststick 2>/dev/null || true
        fi
        
        # Remove boot config changes (comment out, don't delete)
        if [ -f /boot/config.txt ]; then
            sed -i 's/^dtoverlay=dwc2/#dtoverlay=dwc2/' /boot/config.txt 2>/dev/null || true
        fi
        if [ -f /boot/firmware/config.txt ]; then
            sed -i 's/^dtoverlay=dwc2/#dtoverlay=dwc2/' /boot/firmware/config.txt 2>/dev/null || true
        fi
        
        systemctl daemon-reload
        
        ok "Uninstall complete"
        info "Data directory preserved: /opt/ghoststick"
        warn "To completely remove data, run option 3 or: sudo rm -rf /opt/ghoststick"
        ;;
        
    3)
        warn "COMPLETE REMOVAL - ALL DATA WILL BE DELETED"
        echo
        read -r -p "Type 'DELETE' to confirm: " CONFIRM
        
        if [ "$CONFIRM" != "DELETE" ]; then
            err "Confirmation failed. Aborting."
            exit 1
        fi
        
        info "Removing all GhostStick components..."
        
        # Close encrypted volumes
        cryptsetup close ghost_exfil 2>/dev/null || true
        umount /opt/ghoststick/exfil 2>/dev/null || true
        
        # Stop and disable services
        systemctl stop ghoststick-gadget 2>/dev/null || true
        systemctl disable ghoststick-gadget 2>/dev/null || true
        systemctl stop pivot-autossh 2>/dev/null || true
        systemctl disable pivot-autossh 2>/dev/null || true
        systemctl stop pivot-chisel 2>/dev/null || true
        systemctl disable pivot-chisel 2>/dev/null || true
        
        # Remove service files
        rm -f /etc/systemd/system/ghoststick-gadget.service
        rm -f /etc/systemd/system/pivot-autossh.service
        rm -f /etc/systemd/system/pivot-chisel.service
        
        # Remove scripts
        rm -f /usr/local/bin/ghoststick-gadget.sh
        rm -f /usr/local/bin/ghoststick-update.sh
        rm -f /usr/local/bin/ghost-hid-send
        rm -f /usr/local/bin/ghostctl
        
        # Remove configurations
        rm -f /etc/dnsmasq.d/usb0.conf
        rm -f /etc/network/interfaces.d/usb0*
        rm -f /etc/systemd/network/usb0.network
        rm -f /etc/NetworkManager/conf.d/wifi-stealth.conf
        rm -f /etc/sysctl.d/99-usb0-ipv6.conf
        rm -f /etc/profile.d/ghost-pip.sh
        rm -f /etc/profile.d/ghoststick-history.sh
        rm -f /etc/ghoststick-banner
        rm -f /etc/cron.d/ghoststick-update
        
        # Remove USB gadget
        if [ -d "/sys/kernel/config/usb_gadget/ghoststick" ]; then
            echo "" > /sys/kernel/config/usb_gadget/ghoststick/UDC 2>/dev/null || true
            rm -rf /sys/kernel/config/usb_gadget/ghoststick 2>/dev/null || true
        fi
        
        # Remove boot config changes
        if [ -f /boot/config.txt ]; then
            sed -i 's/^dtoverlay=dwc2/#dtoverlay=dwc2/' /boot/config.txt 2>/dev/null || true
        fi
        if [ -f /boot/firmware/config.txt ]; then
            sed -i 's/^dtoverlay=dwc2/#dtoverlay=dwc2/' /boot/firmware/config.txt 2>/dev/null || true
        fi
        
        # Remove data directory
        rm -rf /opt/ghoststick
        
        systemctl daemon-reload
        
        ok "Complete removal finished"
        ok "All GhostStick components deleted"
        ;;
        
    4)
        info "Uninstall cancelled"
        exit 0
        ;;
        
    *)
        err "Invalid option"
        exit 1
        ;;
esac

echo
echo "================================================"
ok "Uninstall process complete"
echo "================================================"
echo
info "You may want to:"
echo "  • Reboot the system: sudo reboot"
echo "  • Review network interfaces: ip addr"
echo "  • Check for remaining configs: ls /etc | grep ghost"
echo
