#!/bin/bash
# GhostCTL HID Module

mod_status() {
    info "HID Engine Status"
    
    local PROFILE
    PROFILE=$(cat "$GS/profile.final" 2>/dev/null || echo "secure")
    local LAYOUT
    LAYOUT=$(cat "$GS/hid.layout" 2>/dev/null || echo "us")
    local ACTIVE
    ACTIVE=$(cat "$GS/hid/active.payload" 2>/dev/null || echo "none")
    
    echo "Profile: $PROFILE"
    echo "Keyboard Layout: $LAYOUT"
    echo "Active Payload: $ACTIVE"
    echo
    
    if [ -e "/dev/hidg0" ]; then
        ok "HID device /dev/hidg0 is ready"
    else
        warn "HID device not available (secure profile or not configured)"
    fi
}

mod_list() {
    info "Available Payloads:"
    
    for os in windows linux macos custom; do
        if [ -d "$GS/hid/$os" ]; then
            echo -e "\n${CYAN}[$os]${RESET}"
            find "$GS/hid/$os" -name "*.txt" -exec basename {} \; 2>/dev/null
        fi
    done
}

mod_set() {
    local PAYLOAD="$1"
    
    if [[ -z "$PAYLOAD" ]]; then
        err "Usage: ghostctl hid set <payload_path>"
        exit 1
    fi
    
    if [ ! -f "$PAYLOAD" ]; then
        # Try relative to hid dir
        if [ -f "$GS/hid/$PAYLOAD" ]; then
            PAYLOAD="$GS/hid/$PAYLOAD"
        else
            err "Payload file not found: $PAYLOAD"
            exit 1
        fi
    fi
    
    echo "$PAYLOAD" > "$GS/hid/active.payload"
    ok "Active payload set to: $PAYLOAD"
}

mod_send() {
    local PAYLOAD="${1:-$(cat "$GS/hid/active.payload" 2>/dev/null)}"
    
    if [[ -z "$PAYLOAD" || ! -f "$PAYLOAD" ]]; then
        err "No payload specified or active payload not found"
        exit 1
    fi
    
    if [ ! -e "/dev/hidg0" ]; then
        err "HID device not available"
        exit 1
    fi
    
    if ! confirm "Send HID payload: $PAYLOAD"; then
        warn "Cancelled."
        exit 0
    fi
    
    info "Sending payload..."
    /usr/local/bin/ghost-hid-send "$PAYLOAD"
    ok "Payload sent."
}

mod_layout() {
    local LAYOUT="$1"
    
    if [[ -z "$LAYOUT" ]]; then
        echo "Current layout: $(cat "$GS/hid.layout")"
        exit 0
    fi
    
    echo "$LAYOUT" > "$GS/hid.layout"
    ok "Keyboard layout set to: $LAYOUT"
    warn "Reboot required to apply."
}

mod_edit() {
    local PAYLOAD="$1"
    
    if [[ -z "$PAYLOAD" ]]; then
        PAYLOAD=$(cat "$GS/hid/active.payload" 2>/dev/null)
    fi
    
    if [[ -z "$PAYLOAD" || ! -f "$PAYLOAD" ]]; then
        err "No payload specified"
        exit 1
    fi
    
    "${EDITOR:-nano}" "$PAYLOAD"
}
