#!/usr/bin/env bash

echo "[20] USB Gadget — Adaptive Composite Engine"

set -euo pipefail

GS="/opt/ghoststick"
STATE="$GS/state"
mkdir -p "$STATE"

###############################################
# 0. RESUME-SAFE STATE MACHINE
###############################################
if [ -f "$STATE/usb.done" ]; then
    echo "[20] USB gadget already configured."
    exit 0
fi
touch "$STATE/usb.start"

###############################################
# 1. DETECT BOOT CONFIG PATHS
###############################################
detect_cfg() {
    for f in /boot/config.txt /boot/firmware/config.txt; do
        [ -f "$f" ] && echo "$f" && return 0
    done
    return 1
}

detect_cmd() {
    for f in /boot/cmdline.txt /boot/firmware/cmdline.txt; do
        [ -f "$f" ] && echo "$f" && return 0
    done
    return 1
}

GCFG=$(detect_cfg)
CMDL=$(detect_cmd)

if [[ -z "$GCFG" || -z "$CMDL" ]]; then
    echo "[20] ERROR: Cannot locate boot configuration files."
    exit 1
fi

###############################################
# 2. ENABLE DWC2 & MODULE LOADING
###############################################
# DWC2 overlay (idempotent)
grep -q "^dtoverlay=dwc2" "$GCFG" || echo "dtoverlay=dwc2" >> "$GCFG"

# Patch cmdline safely (idempotent)
if ! grep -q "modules-load=dwc2,g_ether" "$CMDL"; then
    sed -i 's/rootwait/rootwait modules-load=dwc2,g_ether/' "$CMDL"
fi

###############################################
# 3. PROFILE DECISION
###############################################
PROFILE_FILE="$GS/profile.final"
[ -f "$PROFILE_FILE" ] || echo "secure" > "$PROFILE_FILE"
PROFILE=$(tr -d ' \t' < "$PROFILE_FILE")

###############################################
# 4. HID LAYOUT
###############################################
LAYOUT_FILE="$GS/hid.layout"
[ -f "$LAYOUT_FILE" ] || echo "us" > "$LAYOUT_FILE"
KEYMAP=$(tr -d ' \t' < "$LAYOUT_FILE")

###############################################
# 5. HID REPORT DESCRIPTOR (CORRECTED)
###############################################
HID_DESCRIPTOR_BIN=$'\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7'\
$'\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08'\
$'\x81\x03\x95\x05\x75\x01\x05\x08\x19\x01\x29\x05\x91\x02'\
$'\x95\x01\x75\x03\x91\x03\x95\x06\x75\x08\x15\x00\x25\x65'\
$'\x05\x07\x19\x00\x29\x65\x81\x00\xc0'

###############################################
# 6. PROFILE MAPPING
###############################################
ENABLE_ECM=false
ENABLE_RNDIS=false
ENABLE_HID=false
ENABLE_MASS=false

case "$PROFILE" in
    windows)
        ENABLE_RNDIS=true
        ENABLE_HID=true
        ;;
    linux|macos)
        ENABLE_ECM=true
        ENABLE_HID=true
        ;;
    exfil)
        ENABLE_ECM=true
        ENABLE_HID=true
        ENABLE_MASS=true
        ;;
    secure)
        ENABLE_ECM=true
        ;;
esac

###############################################
# 7. RNDIS CAPABILITY CHECK (HARDENED)
###############################################
if $ENABLE_RNDIS; then

    RNDIS_PATHS=(
        "/lib/modules/$(uname -r)/kernel/drivers/usb/gadget/function"
        "/lib/modules/$(uname -r)/kernel/drivers/usb/gadget/legacy"
        "/lib/modules/$(uname -r)/kernel/drivers/usb/gadget"
    )

    found_rndis=false
    for p in "${RNDIS_PATHS[@]}"; do
        if ls "$p"/*rndis* >/dev/null 2>&1; then
            found_rndis=true
            break
        fi
    done

    if ! $found_rndis; then
        echo "[20] RNDIS NOT SUPPORTED — falling back to ECM."
        ENABLE_RNDIS=false
        ENABLE_ECM=true
    fi
fi

###############################################
# 8. BUILD /usr/local/bin/ghoststick-gadget.sh
###############################################
cat > /usr/local/bin/ghoststick-gadget.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

GDIR="/sys/kernel/config/usb_gadget/ghoststick"

cleanup() {
    if [ -d "$GDIR" ]; then
        echo "" > "$GDIR/UDC" 2>/dev/null || true
        rm -rf "$GDIR/configs/c.1/"* 2>/dev/null || true
        rm -rf "$GDIR/functions/"* 2>/dev/null || true
        rmdir "$GDIR" 2>/dev/null || true
    fi
}

cleanup || true
modprobe libcomposite

mkdir -p "$GDIR"
cd "$GDIR"

echo 0x1d6b > idVendor
echo 0x0104 > idProduct
echo 0x0200 > bcdUSB
echo 0x0100 > bcdDevice

mkdir -p strings/0x409
echo "GS-$(tr -dc A-Z0-9 </dev/urandom | head -c 8)" > strings/0x409/serialnumber
echo "Ghost Labs" > strings/0x409/manufacturer
echo "GhostStick Adaptive Gadget" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "GhostStick Composite" > configs/c.1/strings/0x409/configuration
EOF

###############################################
# 9. ADD ECM (IF ENABLED)
###############################################
if $ENABLE_ECM; then
cat >> /usr/local/bin/ghoststick-gadget.sh <<'EOF'
mkdir -p functions/ecm.usb0
echo "02:00:00:00:00:01" > functions/ecm.usb0/dev_addr
echo "02:00:00:00:00:02" > functions/ecm.usb0/host_addr
ln -s functions/ecm.usb0 configs/c.1/
EOF
fi

###############################################
# 10. ADD RNDIS (IF ENABLED)
###############################################
if $ENABLE_RNDIS; then
cat >> /usr/local/bin/ghoststick-gadget.sh <<'EOF'
mkdir -p functions/rndis.usb0
ln -s functions/rndis.usb0 configs/c.1/
EOF
fi

###############################################
# 11. ADD HID (FIXED)
###############################################
if $ENABLE_HID; then
cat >> /usr/local/bin/ghoststick-gadget.sh <<EOF
mkdir -p functions/hid.usb0
echo 1 > functions/hid.usb0/protocol
echo 1 > functions/hid.usb0/subclass
echo 8 > functions/hid.usb0/report_length
printf '%b' "$HID_DESCRIPTOR_BIN" > functions/hid.usb0/report_desc
echo "$KEYMAP" > functions/hid.usb0/layout
ln -s functions/hid.usb0 configs/c.1/
EOF
fi

###############################################
# 12. ADD MASS STORAGE
###############################################
if $ENABLE_MASS; then
cat >> /usr/local/bin/ghoststick-gadget.sh <<'EOF'
if [ -e /dev/mapper/ghost_exfil ]; then
    mkdir -p functions/mass_storage.usb0
    echo 1 > functions/mass_storage.usb0/stall
    echo "/dev/mapper/ghost_exfil" > functions/mass_storage.usb0/lun.0/file
    ln -s functions/mass_storage.usb0 configs/c.1/
fi
EOF
fi

###############################################
# 13. ACTIVATE GADGET (FIXED)
###############################################
cat >> /usr/local/bin/ghoststick-gadget.sh <<'EOF'
UDC_DEV=$(ls /sys/class/udc | head -n1)
echo "$UDC_DEV" > UDC
EOF

chmod +x /usr/local/bin/ghoststick-gadget.sh

###############################################
# 14. SYSTEMD SERVICE
###############################################
cat > /etc/systemd/system/ghoststick-gadget.service <<EOF
[Unit]
Description=GhostStick Adaptive USB Gadget
After=systemd-udevd.service sys-kernel-config.mount
Before=network.target getty.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ghoststick-gadget.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ghoststick-gadget >/dev/null 2>&1

###############################################
# 15. COMPLETE
###############################################
touch "$STATE/usb.done"
echo "[20] USB gadget initialized (adaptive mode)."
