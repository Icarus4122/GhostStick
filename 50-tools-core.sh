#!/usr/bin/env bash
echo "[50] Core Offense Package — Adaptive Installer"

set -euo pipefail

GS="/opt/ghoststick"
STATE="$GS/state"
CACHE="$GS/cache"
mkdir -p "$STATE" "$CACHE"

###############################################
# 0. RESUME-SAFE CHECK
###############################################
if [ -f "$STATE/tools.done" ]; then
    echo "[50] Tools already installed."
    exit 0
fi
touch "$STATE/tools.start"

###############################################
# 1. ENVIRONMENT DETECTION
###############################################
ARCH=$(uname -m)

IS_ARMV6=false
IS_ARM64=false
IS_AMD64=false

case "$ARCH" in
    armv6l)   IS_ARMV6=true ;;
    aarch64)  IS_ARM64=true ;;
    x86_64)   IS_AMD64=true ;;
esac

PIP="$(command -v pip3 || echo /usr/bin/pip3)"
PIPX="$(command -v pipx  || echo /usr/bin/pipx)"

# Ensure pipx path fix
$PIPX ensurepath >/dev/null 2>&1 || true

###############################################
# 2. OFFLINE / ONLINE CAPABILITY TEST
###############################################
ONLINE=false
timeout 2 bash -c "echo >/dev/tcp/1.1.1.1/53" 2>/dev/null && ONLINE=true

###############################################
# 3. ADAPTIVE FETCH (cache aware)
###############################################
fetch_bin() {
    local URL="$1"
    local OUT="$2"
    local BASE
    BASE="$(basename "$OUT")"

    # 1 — cached
    if [ -f "$CACHE/$BASE" ]; then
        cp "$CACHE/$BASE" "$OUT" && chmod +x "$OUT"
        return 0
    fi

    # 2 — online download
    if $ONLINE; then
        wget -q "$URL" -O "$OUT" 2>/dev/null && {
            cp "$OUT" "$CACHE/$BASE"
            chmod +x "$OUT"
            return 0
        }
    fi

    # 3 — offline fail
    return 1
}

###############################################
# 4. IMPACKET (pip)
###############################################
echo "[50] impacket"
$PIP install --upgrade impacket >/dev/null 2>&1 || true

###############################################
# 5. RESPONDER
###############################################
echo "[50] Responder"
if [ ! -d "/opt/responder/.git" ]; then
    if $ONLINE; then
        git clone --depth 1 https://github.com/lgandx/Responder /opt/responder >/dev/null 2>&1 || true
    fi
fi
chmod -R 755 /opt/responder 2>/dev/null || true

###############################################
# 6. CRACKMAPEXEC (pipx)
###############################################
echo "[50] CME"
$PIPX install crackmapexec >/dev/null 2>&1 || \
$PIPX upgrade crackmapexec >/dev/null 2>&1 || true

###############################################
# 7. EVIL-WINRM (ruby)
###############################################
echo "[50] evil-winrm"
gem install evil-winrm --no-document >/dev/null 2>&1 || \
gem update evil-winrm --no-document >/dev/null 2>&1 || true

###############################################
# 8. BLOODHOUND + INGESTORS
###############################################
echo "[50] bloodhound"
$PIP install bloodhound >/dev/null 2>&1 || true
$PIP install bloodhound-python >/dev/null 2>&1 || true

###############################################
# 9. CHISEL (architecture-aware)
###############################################
echo "[50] chisel"

if $IS_ARMV6; then
    CHISEL_URL="https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_linux_armv6"
elif $IS_ARM64; then
    CHISEL_URL="https://github.com/jpillora/chisel/releases/latest/download/chisel_linux_arm64"
elif $IS_AMD64; then
    CHISEL_URL="https://github.com/jpillora/chisel/releases/latest/download/chisel_linux_amd64"
else
    CHISEL_URL="https://github.com/jpillora/chisel/releases/latest/download/chisel_linux_arm"
fi

fetch_bin "$CHISEL_URL" "/usr/local/bin/chisel" || true

###############################################
# 10. KERBRUTE (architecture-aware)
###############################################
echo "[50] kerbrute"

if $IS_AMD64; then
    KB_URL="https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_linux_amd64"
elif $IS_ARM64; then
    KB_URL="https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_linux_arm64"
else
    KB_URL="https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_linux_arm"
fi

fetch_bin "$KB_URL" "/usr/local/bin/kerbrute" || true

###############################################
# 11. NETEXEC (CME successor)
###############################################
echo "[50] NetExec"
if $ONLINE; then
    $PIPX install git+https://github.com/Pennyw0rth/NetExec.git >/dev/null 2>&1 || \
    $PIPX upgrade git+https://github.com/Pennyw0rth/NetExec.git >/dev/null 2>&1 || true
fi

###############################################
# 12. PEASS Suite
###############################################
echo "[50] PEASS"
mkdir -p /opt/peas

# linpeas
fetch_bin \
    "https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh" \
    "/opt/peas/linpeas.sh" || true

# winpeas
fetch_bin \
    "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe" \
    "/opt/peas/winpeas.exe" || true

chmod -R +x /opt/peas 2>/dev/null || true

###############################################
# 13. FFUF
###############################################
echo "[50] ffuf"
apt-get install -y ffuf >/dev/null 2>&1 || true

###############################################
# 14. WORDLISTS
###############################################
echo "[50] wordlists"
mkdir -p /opt/wordlists

fetch_bin \
    "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/darkweb2017-top10000.txt" \
    "/opt/wordlists/top10k.txt" || true

###############################################
# 15. FINALIZE
###############################################
touch "$STATE/tools.done"
echo "[50] Core offense tools installed."
