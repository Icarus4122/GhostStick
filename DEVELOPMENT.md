# GhostStick Development Notes

## Architecture Overview

GhostStick uses a modular architecture with:

- Numbered installation modules (00-99)
- State machine with resume capability
- GhostCTL operator console with plugin modules
- Adaptive configuration based on hardware and environment

## Module Execution Order

1. **00-preflight** - System checks, dependency installation, state initialization
2. **10-system** - Base system setup, package installation, Python environment
3. **20-usb-gadget** - USB composite gadget configuration (ECM/RNDIS/HID/Mass Storage)
4. **30-networking** - Network stack setup, usb0 interface, DHCP/DNS
5. **40-wifi** - WiFi configuration with stealth roaming
6. **50-tools-core** - Offensive security tools (Impacket, CME, Responder, etc.)
7. **60-hid** - HID payload engine and keystroke injection
8. **70-exfil** - Encrypted LUKS2 exfiltration volume
9. **80-pivot** - Multi-path pivoting (AutoSSH/Chisel/WireGuard)
10. **85-updater** - Auto-update system with safety checks
11. **90-hardening** - Security hardening and stealth features
12. **95-ghostctl** - Operator console installation
13. **99-final** - Finalization, cleanup, banner generation

## State Management

Each module creates a `.done` file in `/opt/ghoststick/state/` when completed.

This allows:

- Resuming interrupted installations
- Skipping completed modules
- Re-running specific modules independently

## Configuration Files

### Runtime Configuration

- `/opt/ghoststick/profile.final` - Active operational profile
- `/opt/ghoststick/pivot.env` - Pivot configuration
- `/opt/ghoststick/security.env` - Security settings
- `/opt/ghoststick/update.env` - Update configuration
- `/opt/ghoststick/wifi.mode` - WiFi mode
- `/opt/ghoststick/hid.layout` - Keyboard layout

### State Files

- `/opt/ghoststick/state/preflight.json` - System fingerprint
- `/opt/ghoststick/state/*.done` - Module completion markers
- `/opt/ghoststick/state/net.stack` - Network stack type
- `/opt/ghoststick/state/usb.capability` - USB gadget capability

### Operational Data

- `/opt/ghoststick/exfil.img` - Encrypted exfil volume
- `/opt/ghoststick/exfil.pass` - Exfil passphrase
- `/opt/ghoststick/hid/` - HID payload library
- `/opt/ghoststick/wifi.home/` - Saved WiFi networks

## GhostCTL Module System

GhostCTL uses a plugin architecture. Each module in `/opt/ghoststick/modules/*.sh` exports functions:

- `mod_status()` - Show module status
- `mod_<action>()` - Execute specific action

Example:

```bash
# Module: wifi.sh
mod_status() { ... }
mod_set() { ... }
mod_add() { ... }
```

Called via: `ghostctl wifi status` or `ghostctl wifi add`

## USB Gadget Profiles

### secure (default)

- ECM network only
- No HID
- Minimal exfil (256MB)
- Maximum stealth

### windows

- RNDIS + HID
- Windows payloads
- Medium exfil (512MB)

### linux

- ECM + HID
- Linux payloads
- Large exfil (1GB)

### macos

- ECM + HID
- macOS payloads
- Large exfil (2GB)

### exfil

- ECM + HID + Mass Storage
- Maximum data exfiltration
- Large volume

## Network Architecture

```txt
Host Computer
     |
  [USB Cable]
     |
  usb0 (172.16.1.1/24) - GhostStick
     |
  [dnsmasq DHCP]
     |
  Host gets 172.16.1.10-50
     |
  [iptables NAT]
     |
  wlan0/eth0 - Internet
```

## Pivot Architecture

Three pivot methods in priority order:

1. **WireGuard** - If configured in `/etc/wireguard/wg0.conf`
2. **AutoSSH** - SSH reverse tunnel to C2 (port 9001)
3. **Chisel** - HTTP tunnel fallback (port 9002)

Configured via `/opt/ghoststick/pivot.env`

## Adding New Modules

### Installation Module

1. Create `modules/XX-mymodule.sh` with proper numbering
2. Add shebang and set -euo pipefail
3. Implement state checking:

   ```bash
   if [ -f "$STATE/mymodule.done" ]; then
       echo "Already configured"
       exit 0
   fi
   ```

4. Do work
5. Mark complete: `touch "$STATE/mymodule.done"`

### GhostCTL Module

1. Create `modules/mymodule.sh`
2. Export `mod_*` functions
3. Use GhostCTL helpers: `ok`, `warn`, `err`, `info`, `confirm`
4. Access via: `ghostctl mymodule action`

## Testing

### Dry Run

```bash
DRYRUN=true ./installer.sh
```

### Selective Installation

Create `run.only`:

```text
00-preflight.sh
10-system.sh
```

### Module Re-run

```bash
sudo bash /opt/ghoststick/modules/50-tools-core.sh
```

## Security Considerations

### Stealth Features

- LED suppression (high stealth)
- MAC randomization
- Minimal logging (20MB journal max, volatile)
- History disabled
- Machine ID regeneration
- MOTD/issue removed

### Hardening

- IPv4 forwarding restrictions
- SYN cookies enabled
- Kernel pointer restriction
- Ptrace scope hardening
- Swap disabled
- Unnecessary services disabled

### Operational Security

- Profile-based capability limiting
- Stealth-aware updates
- Pivot safety checks
- Factory seal for permanent lockdown

## Known Limitations

- RNDIS requires kernel support (not all ARM devices)
- HID requires USB OTG capability
- Some features require internet connectivity
- Factory seal is irreversible

## Future Enhancements

Potential additions:

- USB-C support
- Bluetooth exfiltration
- Web-based management interface
- Custom kernel with additional gadgets
- Remote management via pivot
- Automated payload generation
- Host OS detection and profile auto-switching
- EDR evasion techniques

## Debugging

### Enable Verbose Logging

Add to module:

```bash
set -x  # Enable command tracing
```

### Check Module State

```bash
ls -la /opt/ghoststick/state/
```

### View Service Status

```bash
systemctl status ghoststick-gadget
systemctl status dnsmasq
journalctl -xe
```

### USB Gadget Inspection

```bash
ls -la /sys/kernel/config/usb_gadget/ghoststick/
cat /sys/kernel/config/usb_gadget/ghoststick/UDC
```

## Contributing

When contributing:

1. Follow existing code style
2. Add state checking for resume safety
3. Use consistent error handling
4. Update README with new features
5. Test on actual hardware
6. Document configuration options

## License

MIT License - See LICENSE file
