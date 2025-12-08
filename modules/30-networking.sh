#!/usr/bin/env bash
echo "[30] Networking — Adaptive USB0 Stack"

set -euo pipefail

GS="/opt/ghoststick"
STATE="$GS/state"
mkdir -p "$STATE"

###############################################
# 0. RESUME-SAFE STATE MACHINE
###############################################
if [ -f "$STATE/net.done" ]; then
    echo "[30] Networking already configured."
    exit 0
fi
touch "$STATE/net.start"

###############################################
# 1. WAIT FOR usb0 TO APPEAR (max 3s)
###############################################
# shellcheck disable=SC2034
for i in {1..6}; do
    if ip link show usb0 >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

###############################################
# 2. DETECT ACTIVE NETWORK STACK
###############################################
NETMODE="legacy"

if systemctl is-active --quiet NetworkManager; then
    NETMODE="networkmanager"
elif systemctl is-active --quiet systemd-networkd; then
    NETMODE="networkd"
elif systemctl is-active --quiet dhcpcd; then
    NETMODE="dhcpcd"
fi

echo "[30] Network mode detected: $NETMODE"
echo "$NETMODE" > "$STATE/net.stack"

###############################################
# 3. CLEAN OLD CONFIGS (ALL MODES)
###############################################
rm -f /etc/network/interfaces.d/usb0* 2>/dev/null || true
rm -f /etc/systemd/network/usb0.network 2>/dev/null || true
rm -f /etc/dnsmasq.d/usb0.conf 2>/dev/null || true
mkdir -p /etc/dnsmasq.d

###############################################
# 4. CONFIGURE usb0 STATIC INTERFACE
###############################################
case "$NETMODE" in

    ############################################################
    # A. NetworkManager Mode
    ############################################################
    networkmanager)
        echo "[30] Config: NetworkManager"

        nmcli connection delete usb0 2>/dev/null || true

        # Add connection with predictable settings
        nmcli connection add \
            type ethernet \
            con-name usb0 \
            ifname usb0 \
            ipv4.method manual \
            ipv4.addresses "172.16.1.1/24" \
            ipv6.method ignore

        # Ensure autoconnect + device managed
        nmcli connection modify usb0 connection.autoconnect yes
        nmcli device set usb0 managed yes

        # Reduce route priority so host routes always win
        nmcli connection modify usb0 ipv4.route-metric 200
        nmcli connection up usb0 || true
        ;;

    ############################################################
    # B. systemd-networkd Mode
    ############################################################
    networkd)
        echo "[30] Config: systemd-networkd"

        mkdir -p /etc/systemd/network

        cat > /etc/systemd/network/usb0.network <<EOF
[Match]
Name=usb0

[Network]
Address=172.16.1.1/24
IPForward=ipv4
IPv6AcceptRA=no
EOF

        # Apply instantly
        udevadm trigger
        systemctl restart systemd-networkd
        ;;

    ############################################################
    # C. dhcpcd Mode
    ############################################################
    dhcpcd)
        echo "[30] Config: dhcpcd"

        mkdir -p /etc/network/interfaces.d

        cat > /etc/network/interfaces.d/usb0.cfg <<EOF
auto usb0
allow-hotplug usb0
iface usb0 inet static
    address 172.16.1.1
    netmask 255.255.255.0
EOF

        # Prevent dhcpcd from touching usb0
        if ! grep -q "^denyinterfaces usb0" /etc/dhcpcd.conf; then
            echo "denyinterfaces usb0" >> /etc/dhcpcd.conf
        fi

        systemctl restart dhcpcd
        ;;

    ############################################################
    # D. Legacy Debian Mode
    ############################################################
    *)
        echo "[30] Config: legacy /etc/network/interfaces.d"

        mkdir -p /etc/network/interfaces.d

        cat > /etc/network/interfaces.d/usb0.cfg <<EOF
auto usb0
iface usb0 inet static
    address 172.16.1.1
    netmask 255.255.255.0
EOF
        ;;
esac

###############################################
# 5. Stealth dnsmasq (USB-only)
###############################################
cat > /etc/dnsmasq.d/usb0.conf <<'EOF'
interface=usb0
bind-dynamic
except-interface=lo

# DHCP pool
dhcp-range=172.16.1.10,172.16.1.50,12h
dhcp-option=3,172.16.1.1
dhcp-option=6,172.16.1.1

no-resolv
no-hosts
domain-needed
bogus-priv
quiet-dhcp
quiet-dhcp6
quiet-ra
EOF

systemctl restart dnsmasq || systemctl start dnsmasq
systemctl enable dnsmasq >/dev/null 2>&1

###############################################
# 6. ENABLE IPv4 FORWARDING + STEALTH NAT
###############################################
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1

# NAT for usb0 only (stealth)
iptables -t nat -C POSTROUTING -s 172.16.1.0/24 -j MASQUERADE 2>/dev/null ||
iptables -t nat -A POSTROUTING -s 172.16.1.0/24 -j MASQUERADE

###############################################
# 7. DISABLE IPv6 ON usb0 PERMANENTLY
###############################################
# For current boot
echo 1 > /proc/sys/net/ipv6/conf/usb0/disable_ipv6 2>/dev/null || true

# For all future appearances
mkdir -p /etc/sysctl.d
cat > /etc/sysctl.d/99-usb0-ipv6.conf <<EOF
net.ipv6.conf.usb0.disable_ipv6 = 1
EOF

###############################################
# 8. VERIFY INTERFACE
###############################################
sleep 1
if ip addr show usb0 | grep -q "172.16.1.1"; then
    echo "[30] usb0 UP and configured."
else
    echo "[30] WARNING: usb0 missing IP (will retry next stage)."
fi

###############################################
# 9. DONE
###############################################
touch "$STATE/net.done"
echo "[30] Networking ready (adaptive)."
