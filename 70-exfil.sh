#!/usr/bin/env bash
echo "[70] Encrypted Exfiltration Engine"

set -euo pipefail

GS="/opt/ghoststick"
STATE="$GS/state"
EXFIL_IMG="$GS/exfil.img"
MAP_NAME="ghost_exfil"
PROFILE_FILE="$GS/profile.final"
PASSPHRASE_FILE="$GS/exfil.pass"
CFG="$GS/exfil.cfg"
EXFIL_MNT="$GS/exfil"

mkdir -p "$STATE"

########################################################
# 0. Resume-safe
########################################################
if [ -f "$STATE/exfil.done" ]; then
    echo "[70] Exfil partition already prepared."
    exit 0
fi
touch "$STATE/exfil.start"

cleanup() {
    cryptsetup close "$MAP_NAME" 2>/dev/null || true
}
trap cleanup EXIT

########################################################
# 1. Passphrase handling
########################################################
if [ -f "$PASSPHRASE_FILE" ]; then
    PASSPHRASE=$(cat "$PASSPHRASE_FILE")
else
    PASSPHRASE="ghostpass"
    echo "$PASSPHRASE" > "$PASSPHRASE_FILE"
    chmod 600 "$PASSPHRASE_FILE"
fi

########################################################
# 2. Profile → Dynamic size
########################################################
OS="secure"
[ -f "$PROFILE_FILE" ] && OS=$(tr -d ' \t' < "$PROFILE_FILE")

case "$OS" in
    windows) SIZE_MB=512 ;;
    linux)   SIZE_MB=1024 ;;
    macos)   SIZE_MB=2048 ;;
    secure|*) SIZE_MB=256 ;;
esac

echo "[70] Exfil size: ${SIZE_MB}MB"

########################################################
# 3. Config for other modules
########################################################
cat > "$CFG" <<EOF
size_mb: $SIZE_MB
cipher: aes-xts-plain64
kdf: argon2id
map_name: $MAP_NAME
EOF

########################################################
# 4. Existing image handling
########################################################
if [ -f "$EXFIL_IMG" ]; then
    echo "$PASSPHRASE" | cryptsetup open "$EXFIL_IMG" "$MAP_NAME" \
        --allow-discards -q 2>/dev/null && \
    {
        echo "[70] Existing exfil volume reopened. Checking filesystem..."
        fsck.ext4 -p "/dev/mapper/$MAP_NAME" >/dev/null 2>&1 || true
        touch "$STATE/exfil.done"
        exit 0
    }

    echo "[70] Existing image corrupted → wiping and rebuilding."
    cryptsetup close "$MAP_NAME" 2>/dev/null || true
    rm -f "$EXFIL_IMG"
fi

########################################################
# 5. Allocate image fast (try fallocate)
########################################################
echo "[70] Allocating ${SIZE_MB}MB exfil container..."

if ! fallocate -l "${SIZE_MB}M" "$EXFIL_IMG" 2>/dev/null; then
    dd if=/dev/zero of="$EXFIL_IMG" bs=1M count="$SIZE_MB" status=progress
fi

########################################################
# 6. LUKS2 container creation (adaptive KDF)
########################################################
ARCH=$(uname -m)
# Adjust KDF memory for low-end ARM boards
if [[ "$ARCH" == "armv6l" || "$ARCH" == "armv7l" ]]; then
    PBKDF_MEM=262144   # 256MB
else
    PBKDF_MEM=1048576  # 1GB
fi

echo "$PASSPHRASE" | cryptsetup luksFormat \
    --type luks2 \
    --cipher aes-xts-plain64 \
    --key-size 512 \
    --hash sha256 \
    --iter-time 2000 \
    --pbkdf argon2id \
    --pbkdf-memory "$PBKDF_MEM" \
    --pbkdf-parallel 4 \
    "$EXFIL_IMG" -q

########################################################
# 7. Open volume
########################################################
echo "$PASSPHRASE" | cryptsetup luksOpen "$EXFIL_IMG" "$MAP_NAME" \
    --allow-discards -q

########################################################
# 8. Format (ext4 with safer journaling)
########################################################
mkfs.ext4 -F -q "/dev/mapper/$MAP_NAME"

mkdir -p "$EXFIL_MNT"

########################################################
# 9. Mount (noatime + writeback = less forensic noise)
########################################################
mount -o noatime,data=writeback "/dev/mapper/$MAP_NAME" "$EXFIL_MNT"

########################################################
# 10. Permissions
########################################################
chmod 700 "$EXFIL_MNT"

########################################################
# 11. Complete
########################################################
touch "$STATE/exfil.done"
echo "[70] Encrypted exfiltration volume ready."
