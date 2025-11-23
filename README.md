# GhostStick Zero — Stealth USB Offensive Framework
A modular, adaptive, operator-grade red-team USB implant built for Raspberry Pi Zero-class devices. GhostStick Zero provides covert networking, HID keystroke injection, encrypted exfiltration, multi-path pivoting, and a fully automated installation engine.

---

## 🚀 Features
- Composite USB Gadget (ECM + HID + Mass Storage)
- Adaptive Host Fingerprinting Engine
- Encrypted Exfiltration Volume
- Multi-Pivot System (AutoSSH / Chisel / WireGuard)
- Stealth WiFi Roaming Engine
- Hardened Logging & System Stealth
- Automatic Tool Deployment (Impacket, CME, Responder, Kerbrute, PEAS, etc.)
- Modular Installer with Resume-Safe State Machine

---

## 📦 Installation

### **1. Flash Raspberry Pi OS Lite**
Use Raspberry Pi Imager → Choose **Raspberry Pi OS Lite (32-bit)**.

### **2. Clone Repository**
```bash
git clone https://github.com/<your-repo>/GhostStick-Zero
cd GhostStick-Zero
```

### **3. Run Installer**
```bash
sudo ./installer.sh
```

### **4. Reboot Device**
```bash
sudo reboot
```

GhostStick will initialize composite USB mode on next boot.

---

## 🧩 Project Structure
```
GhostStick-Zero/
│ installer.sh
│ run.only                # Optional: restrict which modules run
│
└── modules/
    ├── 00-preflight.sh
    ├── 10-system.sh
    ├── 20-usb-gadget.sh
    ├── 30-networking.sh
    ├── 32-detect.sh
    ├── 33-profile-selector.sh
    ├── 35-upstream.sh
    ├── 35-route-engine.sh
    ├── 36-pivot-watchdog.sh
    ├── 40-wifi.sh
    ├── 50-tools-core.sh
    ├── 60-hid.sh
    ├── 70-exfil.sh
    ├── 80-pivot.sh
    ├── 85-updater.sh
    ├── 90-hardening.sh
    └── 99-final.sh
```

Each module:
- Runs in numeric order
- Has its own resume-safe `state/*.done` file
- Includes adaptive logic and stealth-aware behaviors

---

## 🛠 Usage

Once plugged into a target system, GhostStick will:

### **1. Auto-detect the host OS**
- DHCP fingerprint
- TTL fingerprint
- EDR presence
- Domain membership

### **2. Select appropriate USB profile**
- Windows → ECM + HID
- Linux/Mac → ECM only
- Domain / EDR detected → Secure mode

### **3. Start pivoting automatically**
- AutoSSH reverse tunnel → port 9001
- Chisel fallback → port 9002
- WireGuard if configured

### **4. Provide operator web/payload hosting**
(If the operator enables additional services)

---

## 🔧 Modifying / Extending Modules

### **Create a new module**
1. Add file inside `modules/` starting with a number:
```
modules/55-custom.sh
```
2. Make it executable:
```bash
chmod +x modules/55-custom.sh
```
3. Installer will automatically run it in order.

### **Restrict to specific modules**
Create a `run.only` file:
```
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

