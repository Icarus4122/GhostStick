#!/usr/bin/env bash
echo "[85] Updater subsystem initializing..."

set -euo pipefail

GS="/opt/ghoststick"
STATE="$GS/state"
UPCFG="$GS/update.env"
PROFILE_FILE="$GS/profile.final"
UPSTREAM="$GS/upstream.json"

mkdir -p "$STATE"

###############################################################
# 0. Resume-safe
###############################################################
if [ -f "$STATE/updater.done" ]; then
    echo "[85] Updater already configured."
    exit 0
fi
touch "$STATE/updater.start"

###############################################################
# 1. Operator environment (defaults)
###############################################################
AUTO_UPDATE="weekly"       # weekly | daily | off
ALLOW_UPDATES="auto"       # auto | force | block
STEALTH_LEVEL="medium"     # low | medium | high
# shellcheck disable=SC2034
SAFE_ONLY="true"           # require upstream to be safe
PKG_MODE="stable"          # stable | bleeding

# shellcheck disable=SC1090
[ -f "$UPCFG" ] && source "$UPCFG"

# Sanitize invalid operator input
case "$AUTO_UPDATE" in weekly|daily|off) ;; *) AUTO_UPDATE="weekly" ;; esac
case "$ALLOW_UPDATES" in auto|force|block) ;; *) ALLOW_UPDATES="auto" ;; esac
case "$STEALTH_LEVEL" in low|medium|high) ;; *) STEALTH_LEVEL="medium" ;; esac
case "$PKG_MODE" in stable|bleeding) ;; *) PKG_MODE="stable" ;; esac

###############################################################
# 2. Load system profile + upstream state
###############################################################
HOST_OS="secure"
[ -f "$PROFILE_FILE" ] && HOST_OS=$(tr -d ' \t' < "$PROFILE_FILE")

NETOK="false"
if [ -f "$UPSTREAM" ]; then
    NET_STATE=$(jq -r '.internet // "false"' "$UPSTREAM" 2>/dev/null || echo "false")
    [ "$NET_STATE" = "true" ] && NETOK="true"
fi

###############################################################
# 3. Stealth & Security Rules
###############################################################
if [ "$STEALTH_LEVEL" = "high" ]; then
    ALLOW_UPDATES="block"
fi

if [ "$HOST_OS" = "secure" ] && [ "$NETOK" != "true" ]; then
    ALLOW_UPDATES="block"
fi

###############################################################
# 4. Block if operator forbids updates
###############################################################
if [ "$ALLOW_UPDATES" = "block" ]; then
    echo "[85] Auto-update disabled by policy."
    touch "$STATE/updater.done"
    exit 0
fi

###############################################################
# 5. Write Updater Script
###############################################################
cat > /usr/local/bin/ghoststick-update.sh <<EOF
#!/usr/bin/env bash
set -euo pipefail

banner() {
    echo "---------------------------------------------"
    echo "\$1"
    echo "---------------------------------------------"
}

banner "[Updater] Executing GhostStick maintenance"

GS="/opt/ghoststick"
UPSTREAM="\$GS/upstream.json"
CFG="\$GS/update.env"

# Load dynamic env
AUTO_UPDATE="weekly"
ALLOW_UPDATES="auto"
STEALTH_LEVEL="medium"
SAFE_ONLY="true"
PKG_MODE="stable"

[ -f "\$CFG" ] && source "\$CFG"

# Fail-safe sanitize
case "\$STEALTH_LEVEL" in low|medium|high) ;; *) STEALTH_LEVEL="medium" ;; esac

###############################################################
# 1. Stealth enforcement (runtime)
###############################################################
if [ "\$STEALTH_LEVEL" = "high" ]; then
    banner "[Updater] High stealth: updates suppressed."
    exit 0
fi

###############################################################
# 2. Internet check
###############################################################
NETOK=false
if [ -f "\$UPSTREAM" ]; then
    NETJSON=\$(jq -r '.internet // "false"' "\$UPSTREAM" 2>/dev/null || echo "false")
    [ "\$NETJSON" = "true" ] && NETOK=true
fi

if ! \$NETOK && [ "\$SAFE_ONLY" = "true" ]; then
    banner "[Updater] Skipping — no safe internet."
    exit 0
fi

###############################################################
# 3. APT Hardened Update (lock-safe)
###############################################################
apt_wait() {
    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
          fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
          fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
        sleep 2
    done
}

apt_wait
banner "[Updater] Running APT update..."
apt update -y -o Acquire::Retries=3
apt_wait
apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

###############################################################
# 4. Python subsystem detection
###############################################################
PYEXE="\$GS/pysbx/bin/python"
if [ ! -x "\$PYEXE" ]; then
    PYEXE="/usr/bin/python3"
fi

PIP="\$PYEXE -m pip"

###############################################################
# 5. Python tool updates
###############################################################
\$PIP install --upgrade pip setuptools wheel >/dev/null 2>&1

if [ "\$PKG_MODE" = "bleeding" ]; then
    \$PIP install --upgrade git+https://github.com/fortra/impacket.git
else
    \$PIP install --upgrade impacket
fi

\$PIP install --upgrade bloodhound bloodhound-python

###############################################################
# 6. pipx upgrades (safe)
###############################################################
safe_pipx_upgrade() {
    if pipx list | grep -q "\$1"; then
        pipx upgrade "\$1" >/dev/null 2>&1 || true
    fi
}

safe_pipx_upgrade crackmapexec
safe_pipx_upgrade netexec

###############################################################
# 7. Responder update
###############################################################
if [ -d "/opt/responder/.git" ]; then
    timeout 10 bash -c "cd /opt/responder && git pull --rebase --stat" || \
    (cd /opt/responder && git reset --hard HEAD && git pull)
fi

###############################################################
# 8. PEAS refresh
###############################################################
wget -q https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh \
    -O /opt/peas/linpeas.sh
wget -q https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe \
    -O /opt/peas/winpeas.exe
chmod +x /opt/peas/*

###############################################################
# 9. Python cache purge
###############################################################
find /opt -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

banner "[Updater] Completed."
EOF

chmod +x /usr/local/bin/ghoststick-update.sh

###############################################################
# 6. Install Cron Scheduler
###############################################################
CRONFILE="/etc/cron.d/ghoststick-update"

case "$AUTO_UPDATE" in
    weekly)
        echo "0 3 * * 0 root /usr/local/bin/ghoststick-update.sh" > "$CRONFILE"
        ;;
    daily)
        echo "0 3 * * * root /usr/local/bin/ghoststick-update.sh" > "$CRONFILE"
        ;;
    off)
        rm -f "$CRONFILE"
        ;;
esac
# required for cron
echo "" >> "$CRONFILE" 2>/dev/null || true

###############################################################
# 7. Done
###############################################################
touch "$STATE/updater.done"
echo "[85] Updater subsystem installed."
