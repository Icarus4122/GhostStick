# GhostStick Zero — Stealth USB Offensive Framework

A modular, adaptive, operator-grade red-team USB implant built for Raspberry Pi Zero-class devices. GhostStick Zero provides covert networking, HID keystroke injection, encrypted exfiltration, multi-path pivoting, and a fully automated installation engine.

---

## 🚀 Features

- **Composite USB Gadget** (ECM/RNDIS + HID + Mass Storage)
- **Adaptive Host Fingerprinting** (OS detection, EDR detection)
- **Encrypted Exfiltration Volume** (LUKS2 with Argon2id)
- **Multi-Pivot System** (AutoSSH / Chisel / WireGuard)
- **Stealth WiFi Roaming** (MAC randomization, open network hopping)
- **Hardened Logging & Stealth** (LED kill, history wipe, minimal logs)
- **Automatic Tool Deployment** (Impacket, CME, NetExec, Responder, Kerbrute, PEASS, etc.)
- **Modular Installer** with Resume-Safe State Machine
- **GhostCTL Console** - Interactive operator control interface

---

## 📦 Installation

### **1. Flash Raspberry Pi OS Lite**

Use Raspberry Pi Imager → Choose **Raspberry Pi OS Lite (32-bit or 64-bit)**.

### **2. Clone Repository**

```bash
git clone https://github.com/Icarus4122/GhostStick
cd GhostStick
```

### **3. Run Installer**

```bash
sudo ./installer.sh
```

The installer will:

- Run all modules in numeric order
- Create state files to track progress
- Allow resumption if interrupted
- Log all activity to `/opt/ghoststick/install.log`

### **4. Reboot Device**

```bash
sudo reboot
```

GhostStick will initialize composite USB mode on next boot.

---

## 🎮 Using GhostCTL

After installation, control GhostStick using the `ghostctl` command:

### **Interactive Menu**

```bash
ghostctl
# or
ghostctl menu
```

### **WiFi Management**

```bash
ghostctl wifi status              # Show WiFi status
ghostctl wifi set auto            # Set WiFi mode (auto/home/roam/off)
ghostctl wifi add SSID passphrase # Add home network
ghostctl wifi list                # List saved networks
ghostctl wifi scan                # Scan for networks
```

### **HID Payloads**

```bash
ghostctl hid status               # Show HID status
ghostctl hid list                 # List available payloads
ghostctl hid set windows/revshell.txt  # Set active payload
ghostctl hid send                 # Execute active payload
ghostctl hid layout us            # Set keyboard layout
```

### **Exfiltration Volume**

```bash
ghostctl exfil status             # Show volume status
ghostctl exfil unlock             # Unlock encrypted volume
ghostctl exfil mount              # Mount volume
ghostctl exfil unmount            # Unmount volume
ghostctl exfil lock               # Lock volume
```

### **Pivot Management**

```bash
ghostctl pivot status             # Show pivot status
ghostctl pivot enable             # Enable pivoting
ghostctl pivot config             # Edit pivot configuration
ghostctl pivot restart autossh    # Restart specific tunnel
ghostctl pivot test               # Test connectivity
```

### **Profile Management**

```bash
ghostctl profile show             # Show current profile
ghostctl profile set windows      # Set profile (secure/windows/linux/macos/exfil)
ghostctl profile list             # List available profiles
```

### **System Commands**

```bash
ghostctl system info              # Show system information
ghostctl system services          # Show service status
ghostctl system reboot            # Reboot device
ghostctl diag full                # Run full diagnostics
```

---

## 🧩 Project Structure

```text
GhostStick/
├── installer.sh                 # Main installation script
├── config.example               # Example configuration file
├── *.env.example                # Example environment configs
├── run.only                     # Optional: restrict which modules run
│
└── modules/
    ├── 00-preflight.sh          # System checks and fingerprinting
    ├── 10-system.sh             # Base system setup
    ├── 20-usb-gadget.sh         # USB gadget configuration
    ├── 30-networking.sh         # Network stack setup
    ├── 40-wifi.sh               # WiFi configuration
    ├── 50-tools-core.sh         # Offensive tools installation
    ├── 60-hid.sh                # HID payload engine
    ├── 70-exfil.sh              # Encrypted exfil volume
    ├── 80-pivot.sh              # Pivot tunnel setup
    ├── 85-updater.sh            # Auto-update system
    ├── 90-hardening.sh          # Security hardening
    ├── 95-ghostctl.sh           # Operator console
    ├── 99-final.sh              # Finalization and cleanup
    │
    └── [GhostCTL Modules]       # Modular command handlers
        ├── wifi.sh
        ├── hid.sh
        ├── exfil.sh
        ├── pivot.sh
        ├── profile.sh
        ├── stealth.sh
        ├── update.sh
        ├── system.sh
        ├── hardening.sh
        ├── seal.sh
        └── diag.sh
```

Each installation module:

- Runs in numeric order
- Has its own resume-safe `state/*.done` file
- Includes adaptive logic and stealth-aware behaviors
- Can be individually executed for updates

---

## 🛠 Operational Modes

GhostStick supports multiple operational profiles:

### **Profile: secure** (Default)

- Minimal attack surface
- USB: ECM network only (no HID)
- Small encrypted exfil volume (256MB)
- No automatic pivoting
- Maximum stealth

### **Profile: windows**

- Optimized for Windows hosts
- USB: RNDIS + HID
- HID payloads enabled
- Medium exfil volume (512MB)
- AutoSSH pivot ready

### **Profile: linux**

- Optimized for Linux hosts
- USB: ECM + HID
- Linux-specific payloads
- Large exfil volume (1GB)

### **Profile: macos**

## 🔧 Configuration

### **Operator Configuration Files**

All configuration files are located in `/opt/ghoststick/`:

- **pivot.env** - Pivot tunnel settings
- **security.env** - Security and stealth settings
- **update.env** - Auto-update configuration
- **wifi.mode** - WiFi operational mode
- **profile.final** - Active operational profile
- **hid.layout** - Keyboard layout for HID

Example configuration templates are provided in the repository.

### **Custom HID Payloads**

Create custom payloads in `/opt/ghoststick/hid/custom/`:

```bash
nano /opt/ghoststick/hid/custom/my_payload.txt
```

Payload syntax:

```text
DELAY 1000           # Wait 1 second
GUI r                # Windows key + R
DELAY 300
STRING notepad       # Type string
ENTER                # Press Enter
```

### **WiFi Home Networks**

Add trusted WiFi networks:

```bash
ghostctl wifi add "MyNetwork" "password123"
```

Networks are stored encrypted in `/opt/ghoststick/wifi.home/`

### **Restrict Module Installation**

Create a `run.only` file to install specific modules only:

```txt
00-preflight.sh
10-system.sh
20-usb-gadget.sh
50-tools-core.sh
```

Installer will execute *only* these modules.

### **Create a new module**

1. Add file inside `modules/` starting with a number:

```txt
## 🔐 Security & Stealth Features

### **Stealth Levels**

**Low**: Basic operational security
- Standard logging enabled
- Services visible

**Medium** (Default): Balanced stealth
- LED indicators disabled
- MAC randomization enabled
- Minimal logging
- History disabled

**High**: Maximum stealth
- All network beaconing suppressed
- Auto-updates disabled
- Zero persistent logs
- Randomized identifiers
## 🧪 Build System

GhostStick's installer features:
- **Dry-run mode**: `DRYRUN=true ./installer.sh`
- **Resume-safe**: Interrupted installations can continue from last completed module
- **Comprehensive logging**: `/opt/ghoststick/install.log`
- **State tracking**: Per-module `.done` files in `/opt/ghoststick/state/`
- **Error recovery**: Graceful handling of partial installations
- **Selective installation**: Use `run.only` to install specific modules

### **Troubleshooting**

View installation status:
```bash
ghostctl diag modules
```

View installation logs:

```bash
cat /opt/ghoststick/install.log
```

Re-run a specific module:

```bash
sudo bash /opt/ghoststick/modules/50-tools-core.sh
```

Full diagnostics:

```bash
ghostctl diag full
```

- Swap disabled
- Kernel hardening (SYN cookies, IP forwarding restrictions)
- SSH hardening with configurable password auth
- Unnecessary services disabled

### **Factory Seal Mode**

Apply irreversible lockdown:

```bash
ghostctl seal apply
```

This will:

- Remove operator configuration files
- Wipe installation logs
- Lock critical system files with chattr +i
- Disable further configuration changes
- **WARNING: Cannot be undone!**

### **Restrict to specific modules**

Create a `run.only` file:

```text
10-system.sh
20-usb-gadget.sh
50-tools-core.sh
```

Installer will execute *only* these.

---

## 🧪 Build System

GhostStick's installer:

- Supports dry-run mode (`DRYRUN=true ./installer.sh`)
- Logs every module in `/opt/ghoststick/install.log`
- Protects modules using per-stage state files
- Recovers from partial installations safely

---

## 🔐 Security / Stealth Considerations

- LEDs disabled
- MAC randomized
- Journald shrunk + aged out
- System identity removed (motd, issue, issue.net)
- Bash history fully disabled
- Optional **Factory Seal Mode** prevents modifications

---

## ⚠ Legal Notice

GhostStick Zero is an offensive security research tool.  
Use only on systems you own or have explicit authorization to test.

---

## 🤝 Contributing

Pull requests welcome!  
For major changes, open an issue first to discuss direction.

---

## 📄 License

MIT License — free for personal and commercial use.

---

## 👻 Closing Note

GhostStick Zero is designed to be:

- Fast to deploy
- Safe to operate covertly
- Easy to extend
- Extremely stealthy

Happy hunting, operator.
