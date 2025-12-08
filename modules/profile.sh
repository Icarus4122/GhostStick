#!/bin/bash
# GhostCTL Profile Module

mod_show() {
    info "Current Profile Configuration"
    
    local PROFILE
    PROFILE=$(cat "$GS/profile.final" 2>/dev/null || echo "secure")
    
    echo "Active Profile: ${GREEN}$PROFILE${RESET}"
    echo
    
    case "$PROFILE" in
        secure)
            echo "  • Minimal attack surface"
            echo "  • USB: ECM network only"
            echo "  • HID: Disabled"
            echo "  • Exfil: 256MB encrypted"
            echo "  • Pivot: Disabled"
            ;;
        windows)
            echo "  • Optimized for Windows hosts"
            echo "  • USB: RNDIS + HID"
            echo "  • HID: Enabled with Windows payloads"
            echo "  • Exfil: 512MB encrypted"
            ;;
        linux)
            echo "  • Optimized for Linux hosts"
            echo "  • USB: ECM + HID"
            echo "  • HID: Enabled with Linux payloads"
            echo "  • Exfil: 1GB encrypted"
            ;;
        macos)
            echo "  • Optimized for macOS hosts"
            echo "  • USB: ECM + HID"
            echo "  • HID: Enabled with macOS payloads"
            echo "  • Exfil: 2GB encrypted"
            ;;
        exfil)
            echo "  • Maximum exfiltration capability"
            echo "  • USB: ECM + HID + Mass Storage"
            echo "  • HID: Enabled"
            echo "  • Exfil: Large encrypted volume"
            ;;
    esac
}

mod_set() {
    local PROFILE="$1"
    
    case "$PROFILE" in
        secure|windows|linux|macos|exfil)
            echo "$PROFILE" > "$GS/profile.final"
            ok "Profile set to: $PROFILE"
            warn "Reboot required to apply changes"
            ;;
        *)
            err "Invalid profile. Choose: secure, windows, linux, macos, exfil"
            exit 1
            ;;
    esac
}

mod_list() {
    info "Available Profiles:"
    echo
    echo "  ${GREEN}secure${RESET}   - Minimal footprint, maximum stealth"
    echo "  ${CYAN}windows${RESET}  - Windows-optimized configuration"
    echo "  ${CYAN}linux${RESET}    - Linux-optimized configuration"
    echo "  ${CYAN}macos${RESET}    - macOS-optimized configuration"
    echo "  ${YELLOW}exfil${RESET}    - Maximum exfiltration mode"
}
