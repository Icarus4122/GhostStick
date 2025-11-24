#!/bin/bash
echo "---------------------------------------------"
echo "[99] Finalizing GhostStick — Seal + Cleanup"
echo "---------------------------------------------"

set -euo pipefail

GS="/opt/ghoststick"
STATE="$GS/state"
SECENV="$GS/security.env"

mkdir -p "$STATE"

###############################################################
# 0. Resume-safe
###############################################################
if [ -f "$STATE/final.done" ]; then
    echo "[99] Finalization already completed."
    exit 0
fi
touch "$STATE/final.start"

###############################################################
# 1. Load operator policy
###############################################################
STEALTH_LEVEL="medium"   
WIPE_HISTORY="true"
WIPE_PKG_CACHE="true"
FACTORY_SEAL="false"

# shellcheck disable=SC1090
[ -f "$SECENV" ] && source "$SECENV"

###############################################################
# 2. Cleanup temporary caches
###############################################################
echo "[99] Cleaning caches..."

if [ "$WIPE_PKG_CACHE" = "true" ]; then
    apt-get clean >/dev/null 2>&1 || true
    rm -rf /root/.cache/pip 2>/dev/null || true
fi

# Safe wipe: do NOT delete directory you're executing from
TMPDIR=$(dirname "$(readlink -f "$0")")
for d in /tmp /var/tmp; do
    find "$d" -mindepth 1 -maxdepth 1 ! -path "$TMPDIR/*" -exec rm -rf {} + 2>/dev/null || true
done

###############################################################
# 3. Disable shell history (multi-shell)
###############################################################
if [ "$WIPE_HISTORY" = "true" ]; then
    cat > /etc/profile.d/ghoststick-history.sh <<'EOF'
# GhostStick Zero — history disabled
export HISTSIZE=0
export HISTFILESIZE=0
unset HISTFILE
# Other shells
export SAVEHIST=0
export HISTFILE=
EOF

    rm -f /root/.bash_history 2>/dev/null
    rm -f /home/*/.bash_history 2>/dev/null
    rm -f /home/*/.zsh_history 2>/dev/null

    echo "[99] Shell history disabled."
fi

###############################################################
# 4. Build dynamic banner
###############################################################
# shellcheck disable=SC2034
PROFILE_STRING=$(cat /opt/ghoststick/profile.final 2>/dev/null || echo "unknown")

cat > /etc/ghoststick-banner <<'EOF'
==============================================
             ('-. .-.               .-')    .-') _           .-')    .-') _                    .-. .-')        
            ( OO )  /              ( OO ). (  OO) )         ( OO ). (  OO) )                   \  ( OO )       
  ,----.    ,--. ,--. .-'),-----. (_)---\_)/     '._       (_)---\_)/     '._ ,-.-')   .-----. ,--. ,--.       
 '  .-./-') |  | |  |( OO'  .-.  '/    _ | |'--...__)      /    _ | |'--...__)|  |OO) '  .--./ |  .'   /       
 |  |_( O- )|   .|  |/   |  | |  |\  :` `. '--.  .--'      \  :` `. '--.  .--'|  |  \ |  |('-. |      /,       
 |  | .--, \|       |\_) |  |\|  | '..`''.)   |  |          '..`''.)   |  |   |  |(_//_) |OO  )|     ' _)      
(|  | '. (_/|  .-.  |  \ |  | |  |.-._)   \   |  |         .-._)   \   |  |  ,|  |_.'||  |`-'| |  .   \        
 |  '--'  | |  | |  |   `'  '-'  '\       /   |  |         \       /   |  | (_|  |  (_'  '--'\ |  |\   \       
  `------'  `--' `--'     `-----'  `-----'    `--'          `-----'    `--'   `--'     `-----' `--' '--' 
                               GhostStick Zero — Ready
==============================================
Profile:    $PROFILE_STRING
Stealth:    $STEALTH_LEVEL

Modules Loaded:
  • Composite USB Gadget
  • Adaptive Networking Stack
  • Host Fingerprinting Engine
  • Stealth WiFi Roaming
  • Encrypted Exfil Partition
  • Multi-Pivot Engine (SSH/Chisel/WG)
  • Hardened Kernel & Journaling

Operate carefully. Stealth is active.
==============================================
EOF

###############################################################
# 5. Auto-display banner for interactive shells
###############################################################
if [ "$STEALTH_LEVEL" != "high" ]; then
    for userdir in /home/*; do
        [ -d "$userdir" ] || continue
        if [ -f "$userdir/.bashrc" ]; then
            if ! grep -q "ghoststick-banner" "$userdir/.bashrc" 2>/dev/null; then
                echo "cat /etc/ghoststick-banner" >> "$userdir/.bashrc"
            fi
        fi
    done
fi

###############################################################
# 6. Factory Seal Mode
###############################################################
if [ "$FACTORY_SEAL" = "true" ]; then
    echo "[99] Applying factory-seal protections..."

    rm -f /opt/ghoststick/security.env
    rm -f /opt/ghoststick/operator.force

    rm -rf /opt/ghoststick/install.log 2>/dev/null
    rm -rf /var/log/apt/* 2>/dev/null
    rm -rf /var/log/dpkg.log 2>/dev/null

    [ -f /etc/ghoststick-banner ] && chattr +i /etc/ghoststick-banner 2>/dev/null
    [ -f /etc/profile.d/ghoststick-history.sh ] && chattr +i /etc/profile.d/ghoststick-history.sh 2>/dev/null

    echo "[99] Factory seal applied — irreversible."
fi

###############################################################
# 7. Complete
###############################################################
touch "$STATE/final.done"
echo "[99] GhostStick build complete."
echo "---------------------------------------------"
echo "[00] Preflight Complete • GhostStick Ready"
echo "---------------------------------------------"
