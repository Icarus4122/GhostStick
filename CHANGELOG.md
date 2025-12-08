# GhostStick Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-08

### Added

- Initial release of GhostStick Zero
- Modular installation system with 13 core modules
- Resume-safe installer with state machine
- USB composite gadget support (ECM/RNDIS/HID/Mass Storage)
- 5 operational profiles (secure, windows, linux, macos, exfil)
- HID keystroke injection engine with payload library
- LUKS2 encrypted exfiltration volume
- Multi-path pivoting (AutoSSH/Chisel/WireGuard)
- Stealth WiFi roaming with MAC randomization
- GhostCTL operator console with 12 module commands
- Comprehensive security hardening
- Automatic offensive tool deployment
- 3 stealth levels (low, medium, high)
- Factory seal mode for permanent lockdown
- Complete documentation (README, QUICKSTART, DEVELOPMENT, CONTRIBUTING)
- Example configuration templates

### Security

- Kernel hardening (SYN cookies, pointer restrictions)
- Minimal logging (20MB volatile journal)
- Shell history disabled
- LED suppression option
- SSH hardening with configurable auth
- Swap disabled
- Machine ID regeneration
- MOTD/issue removal

### Tools Included

- Impacket suite
- CrackMapExec & NetExec
- Responder
- Evil-WinRM
- BloodHound & Ingestors
- Chisel
- Kerbrute
- PEASS suite (LinPEAS/WinPEAS)
- ffuf

## [Unreleased]

### Planned

- Host OS auto-detection and profile switching
- Web-based management interface
- Bluetooth exfiltration support
- Additional EDR evasion techniques
- Custom kernel with extended gadgets
- Remote management via pivot tunnel
- Automated payload generation
- USB-C support improvements

---

## Version History

- **1.0.0** - Initial stable release
