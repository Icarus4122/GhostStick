#!/bin/bash
# GhostCTL Seal Module

mod_status() {
    if grep -q "FACTORY_SEAL.*true" "$GS/security.env" 2>/dev/null; then
        ok "System is sealed (factory mode)"
    else
        warn "System is not sealed"
    fi
}

mod_apply() {
    echo
    warn "======================================="
    warn "  FACTORY SEAL - IRREVERSIBLE ACTION"
    warn "======================================="
    echo
    echo "This will:"
    echo "  • Remove all operator configuration files"
    echo "  • Wipe installation logs"
    echo "  • Lock critical system files"
    echo "  • Disable configuration changes"
    echo
    
    if ! confirm "Apply PERMANENT factory seal"; then
        warn "Cancelled."
        exit 0
    fi
    
    echo
    read -r -p "Type 'SEAL' to confirm: " confirmation
    
    if [ "$confirmation" != "SEAL" ]; then
        err "Confirmation failed. Aborted."
        exit 1
    fi
    
    # Set factory seal flag
    mkdir -p "$GS"
    
    if [ -f "$GS/security.env" ]; then
        sed -i 's/FACTORY_SEAL=.*/FACTORY_SEAL="true"/' "$GS/security.env"
    else
        echo 'FACTORY_SEAL="true"' > "$GS/security.env"
    fi
    
    # Run final module to apply seal
    bash /opt/ghoststick/modules/99-final.sh
    
    ok "System sealed. Configuration locked."
}
