#!/bin/bash
echo "---------------------------------------------"
echo "[90] Hardening Engine — Stealth + Security"
echo "---------------------------------------------"

set -euo pipefail

GS="/opt/ghoststick"
STATE="$GS/state"
SECENV="$GS/security.env"

mkdir -p "$STATE"

###############################################################
# 0. Resume-safe state machine
###############################################################
if [ -f "$STATE/hardening.done" ]; then
    echo "[90] Hardening already applied."
    exit 0
fi
touch "$STATE/hardening.start"

###############################################################
# 1. Load operator policy
###############################################################
STEALTH_LEVEL="medium"   # low | medium | high
RANDOMIZE_HOSTNAME="true"
RANDOMIZE_MAC="true"
MINIMIZE_LOGS="true"
DISABLE_SERVICES="true"
KERNEL_HARDENING="true"
ALLOW_PASSWORD_SSH="true"

# shellcheck disable=SC1090
[ -f "$SECENV" ] && source "$SECENV"

###############################################################
# 2. Hostname Randomization
###############################################################
if [ "$RANDOMIZE_HOSTNAME" = "true" ]; then
    NEW_HOST="GSZ-$((1000 + RANDOM % 8999))"

    echo "$NEW_HOST" > /etc/hostname

    # Cleanly replace old hostnames
    sed -i "s/raspberrypi/$NEW_HOST/g" /etc/hosts
    sed -i "s/127.0.1.1.*/127.0.1.1    $NEW_HOST/g" /etc/hosts

    echo "[90] Hostname randomized → $NEW_HOST"
fi

###############################################################
# 3. LED Kill (high stealth)
###############################################################
if [ "$STEALTH_LEVEL" = "high" ]; then
    echo none > /sys/class/leds/led0/trigger 2>/dev/null || true
    echo none > /sys/class/leds/led1/trigger 2>/dev/null || true
    echo "[90] LEDs disabled (high stealth)."
fi

###############################################################
# 4. MAC Randomization
###############################################################
if [ "$RANDOMIZE_MAC" = "true" ]; then
    mkdir -p /etc/network/if-pre-up.d

cat > /etc/network/if-pre-up.d/macspoof <<'EOF'
#!/bin/bash
MAC=$(printf '02:%02X:%02X:%02X:%02X:%02X' \
    $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
ip link set dev wlan0 address "$MAC" 2>/dev/null
ip link set dev eth0 address "$MAC" 2>/dev/null
EOF

    chmod +x /etc/network/if-pre-up.d/macspoof
    echo "[90] MAC randomization enabled."
fi

###############################################################
# 5. Journaling Minimization
###############################################################
if [ "$MINIMIZE_LOGS" = "true" ]; then
    sed -i 's/#SystemMaxUse=.*/SystemMaxUse=20M/' /etc/systemd/journald.conf
    sed -i 's/#SystemMaxFileSize=.*/SystemMaxFileSize=5M/' /etc/systemd/journald.conf
    sed -i 's/#Storage=.*/Storage=volatile/' /etc/systemd/journald.conf

    systemctl restart systemd-journald 2>/dev/null
    echo "[90] Journald minimized."
fi

###############################################################
# 6. Remove identifying surface
###############################################################
rm -f /etc/motd /etc/issue /etc/issue.net 2>/dev/null

rm -f /etc/machine-id 2>/dev/null
systemd-machine-id-setup >/dev/null 2>&1

echo "[90] Identifying system artifacts removed."

###############################################################
# 7. SSH Hardening — PASSWORD ENABLED SAFELY
###############################################################
# Regenerate host keys (optional)
if [ -f /etc/ssh/ssh_host_rsa_key ]; then
    rm -f /etc/ssh/ssh_host_* 2>/dev/null
    dpkg-reconfigure openssh-server >/dev/null 2>&1
    echo "[90] SSH keys regenerated."
fi

# Ensure PasswordAuthentication YES (explicit)
if [ "$ALLOW_PASSWORD_SSH" = "true" ]; then
    if grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
        sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    else
        echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
    fi
    echo "[90] SSH password authentication enabled."
else
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "[90] SSH password authentication disabled (policy)."
fi

# PermitRootLogin (locked but usable)
if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
else
    echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
fi

# General SSH Hardening
sed -i 's/#X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config

systemctl restart ssh 2>/dev/null

###############################################################
# 8. Disable unnecessary services
###############################################################
if [ "$DISABLE_SERVICES" = "true" ]; then
    systemctl disable --now avahi-daemon 2>/dev/null
    systemctl disable --now triggerhappy 2>/dev/null
    systemctl disable --now cups 2>/dev/null
    echo "[90] Non-essential services disabled."
fi

###############################################################
# 9. Kernel Hardening
###############################################################
if [ "$KERNEL_HARDENING" = "true" ]; then
cat >> /etc/sysctl.conf <<EOF

# GhostStick Hardening Rules
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.tcp_syncookies=1
net.ipv4.conf.all.rp_filter=1
kernel.kptr_restrict=2
kernel.yama.ptrace_scope=2
EOF

    sysctl -p >/dev/null
    echo "[90] Kernel parameters hardened."
fi

###############################################################
# 10. Disable Swap
###############################################################
swapoff -a 2>/dev/null || true
sed -i '/swap/d' /etc/fstab
echo "[90] Swap disabled."

###############################################################
# 11. Finalize
###############################################################
touch "$STATE/hardening.done"
echo "[90] Hardening complete."