#!/bin/bash
# GhostCTL v2 — Advanced Operator Console
# Supports color, completion, menu UI, dynamic commands.

GS="/opt/ghoststick"
MODDIR="$GS/modules"
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$MODDIR"

# Copy GhostCTL module files to /opt/ghoststick/modules/
for mod in wifi hid exfil pivot profile stealth update system hardening seal diag menu; do
    if [ -f "$INSTALL_DIR/${mod}.sh" ]; then
        cp "$INSTALL_DIR/${mod}.sh" "$MODDIR/" 2>/dev/null || true
    fi
done

###########################################
# COLORS (ANSI Safe)
###########################################
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

ok()    { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
err()   { echo -e "${RED}[ERR]${RESET} $1"; }
info()  { echo -e "${CYAN}[INFO]${RESET} $1"; }

###########################################
# BANNER
###########################################
banner() {
    echo -e "${BLUE}================================================${RESET}"
    echo -e "${BLUE}                  GhostCTL v2                  ${RESET}"
    echo -e "${BLUE}================================================${RESET}"
    echo -e "Profile:  $(cat "$GS/profile.final" 2>/dev/null || echo unknown)"
    echo -e "Stealth:  $(grep STEALTH_LEVEL "$GS/security.env" 2>/dev/null | cut -d= -f2)"
    echo
}

###########################################
# CONFIRMATION HANDLER
###########################################
confirm() {
    read -r -p "Confirm ($1)? [y/N] " ans
    [[ "$ans" == "y" || "$ans" == "Y" ]]
}

###########################################
# MODULE LOADER (Plugin System)
###########################################
run_module() {
    MODULE="$1"
    ACTION="$2"
    shift 2

    MODULE_FILE="$MODDIR/$MODULE.sh"

    if [[ ! -f "$MODULE_FILE" ]]; then
        err "Unknown module: $MODULE"
        exit 1
    fi

    # shellcheck source=/dev/null
    source "$MODULE_FILE"

    if ! type "mod_$ACTION" >/dev/null 2>&1; then
        err "Unknown action '$ACTION' for module '$MODULE'"
        echo "Run: ghostctl help $MODULE"
        exit 1
    fi

    "mod_$ACTION" "$@"
}

###########################################
# HELP SYSTEM
###########################################
usage() {
    echo -e "${YELLOW}Usage:${RESET} ghostctl <module> <action> [options]"
    echo
    echo -e "${CYAN}Core Modules:${RESET}"
    echo "  wifi       WiFi control"
    echo "  hid        HID payload engine"
    echo "  exfil      Encrypted exfil volume"
    echo "  pivot      Pivot tunnels"
    echo "  profile    Set/show profile"
    echo "  stealth    Stealth level mgmt"
    echo "  update     Updater system"
    echo "  system     Reboot/shutdown"
    echo "  hardening  Apply/view hardening"
    echo "  seal       Permanent lockdown"
    echo "  diag       Diagnostics"
    echo "  menu       Interactive menu"
}

###########################################
# INTERACTIVE MENU UI
###########################################
menu() {
    while true; do
        clear
        banner
        echo -e "${CYAN}Select an action:${RESET}"
        echo " 1) WiFi Control"
        echo " 2) HID Payloads"
        echo " 3) Exfil Volume"
        echo " 4) Pivot Engine"
        echo " 5) Profile / Stealth"
        echo " 6) Update System"
        echo " 7) Diagnostics"
        echo " 8) Exit"
        echo
        read -r -p "> " sel

        case "$sel" in
            1) ghostctl wifi status ;;
            2) ghostctl hid status ;;
            3) ghostctl exfil status ;;
            4) ghostctl pivot status ;;
            5) ghostctl profile show ;;
            6) ghostctl update status ;;
            7) ghostctl diag preflight ;;
            8) exit 0 ;;
        esac

        echo
        read -r -p "Press ENTER to continue..."
    done
}

###########################################
# MAIN DISPATCH
###########################################
banner

CMD="$1"
ACTION="$2"

# If no arguments → show menu
if [[ -z "$CMD" ]]; then
    menu
    exit 0
fi

case "$CMD" in
    help)
        usage ;;
    menu)
        menu ;;
    *)
        run_module "$CMD" "$ACTION" "$@" ;;
esac
