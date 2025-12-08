#!/bin/bash
# GhostCTL Exfil Module

mod_status() {
    info "Exfil Volume Status"
    
    local IMG="$GS/exfil.img"
    local MAP="/dev/mapper/ghost_exfil"
    local MNT="$GS/exfil"
    
    if [ ! -f "$IMG" ]; then
        warn "Exfil image not created"
        return
    fi
    
    echo "Image: $IMG ($(du -h "$IMG" | cut -f1))"
    
    if [ -e "$MAP" ]; then
        ok "Volume unlocked"
        
        if mountpoint -q "$MNT" 2>/dev/null; then
            ok "Mounted at: $MNT"
            echo
            df -h "$MNT" | tail -1
        else
            warn "Volume unlocked but not mounted"
        fi
    else
        warn "Volume locked"
    fi
}

mod_unlock() {
    local IMG="$GS/exfil.img"
    local MAP="ghost_exfil"
    local PASSFILE="$GS/exfil.pass"
    
    if [ ! -f "$IMG" ]; then
        err "Exfil image not found"
        exit 1
    fi
    
    if [ -e "/dev/mapper/$MAP" ]; then
        ok "Volume already unlocked"
        exit 0
    fi
    
    if [ -f "$PASSFILE" ]; then
        cat "$PASSFILE" | cryptsetup open "$IMG" "$MAP" --allow-discards
        ok "Volume unlocked"
    else
        cryptsetup open "$IMG" "$MAP" --allow-discards
    fi
}

mod_lock() {
    local MAP="ghost_exfil"
    local MNT="$GS/exfil"
    
    if mountpoint -q "$MNT" 2>/dev/null; then
        umount "$MNT"
        ok "Unmounted"
    fi
    
    if [ -e "/dev/mapper/$MAP" ]; then
        cryptsetup close "$MAP"
        ok "Volume locked"
    else
        warn "Volume not open"
    fi
}

mod_mount() {
    local MAP="/dev/mapper/ghost_exfil"
    local MNT="$GS/exfil"
    
    if [ ! -e "$MAP" ]; then
        err "Volume not unlocked. Run: ghostctl exfil unlock"
        exit 1
    fi
    
    mkdir -p "$MNT"
    mount -o noatime,data=writeback "$MAP" "$MNT"
    ok "Mounted at: $MNT"
}

mod_unmount() {
    local MNT="$GS/exfil"
    
    if mountpoint -q "$MNT" 2>/dev/null; then
        umount "$MNT"
        ok "Unmounted"
    else
        warn "Not mounted"
    fi
}

mod_wipe() {
    if ! confirm "WIPE exfil volume (IRREVERSIBLE)"; then
        warn "Cancelled."
        exit 0
    fi
    
    mod_lock
    
    rm -f "$GS/exfil.img"
    ok "Exfil volume wiped"
}

mod_size() {
    local IMG="$GS/exfil.img"
    
    if [ -f "$IMG" ]; then
        du -h "$IMG"
    else
        echo "No exfil image exists"
    fi
}

mod_backup() {
    local DEST="${1:-/tmp/exfil-backup.img}"
    local IMG="$GS/exfil.img"
    
    if [ ! -f "$IMG" ]; then
        err "No exfil image to backup"
        exit 1
    fi
    
    if ! confirm "Backup exfil to: $DEST"; then
        warn "Cancelled."
        exit 0
    fi
    
    cp "$IMG" "$DEST"
    ok "Backup created: $DEST"
}
