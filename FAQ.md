# GhostStick - Frequently Asked Questions

## Installation & Setup

### Q: What hardware do I need?

**A:** Raspberry Pi Zero W, Zero 2 W, or any Pi with USB OTG capability. Also tested on Pi 4/5.

### Q: Which Raspberry Pi OS version should I use?

**A:** Raspberry Pi OS Lite (32-bit or 64-bit). Both Bullseye and Bookworm are supported.

### Q: Can I install on existing Pi OS installation?

**A:** Yes, but fresh installation recommended. The installer is resume-safe if interrupted.

### Q: How long does installation take?

**A:** 15-30 minutes depending on internet speed and hardware. Pi Zero is slower than Pi 4/5.

### Q: Installation failed, can I resume?

**A:** Yes! Just run `sudo ./installer.sh` again. The state machine will skip completed modules.

---

## USB Gadget & Connectivity

### Q: Why doesn't the USB gadget appear on the host?

**A:** Common causes:

- Not rebooted after installation
- Wrong USB port (must use USB data port, not power-only)
- Profile set to "secure" (disables some features)
- Cable is power-only (needs data cable)

Check with: `ghostctl diag usb`

### Q: Windows doesn't recognize the device

**A:**

- Set profile to "windows": `ghostctl profile set windows; sudo reboot`
- Windows needs RNDIS driver (should auto-install)
- Check Device Manager for unknown devices

### Q: My Linux host won't connect

**A:**

- Use "linux" profile: `ghostctl profile set linux; sudo reboot`
- Check `ip addr` on host for usb0/eth1 interface
- May need to manually bring up interface: `sudo ip link set usb0 up`

### Q: Can I use multiple profiles at once?

**A:** No, profiles are mutually exclusive. Choose one that matches your primary target OS.

---

## HID Keystrokes

### Q: HID keystrokes aren't working

**A:** Check:

- Profile must not be "secure" (HID disabled in secure mode)
- Device `/dev/hidg0` must exist: `ls -la /dev/hidg0`
- Verify with: `ghostctl hid status`

### Q: Wrong keyboard layout being sent

**A:** Change layout: `ghostctl hid layout uk` (or de, fr, etc.) then reboot

### Q: Can I create custom payloads?

**A:** Yes! Create files in `/opt/ghoststick/hid/custom/` using Ducky Script syntax.

### Q: Payloads typing too fast/slow?

**A:** Edit `/usr/local/bin/ghost-hid-send` and adjust `time.sleep()` values.

---

## Networking & Pivoting

### Q: Host can't reach internet through GhostStick

**A:**

- GhostStick must have internet (WiFi/Ethernet)
- Check NAT: `sudo iptables -t nat -L`
- Verify routing: `ghostctl diag network`

### Q: How do I setup pivot to my C2 server?

**A:**

```bash
ghostctl pivot enable
ghostctl pivot config
# Edit PIVOT_HOST, PIVOT_PORT, PIVOT_USER
ghostctl pivot restart
```

### Q: Pivot tunnel won't connect

**A:**

- Test connectivity: `ghostctl pivot test`
- Check logs: `ghostctl pivot logs autossh`
- Verify firewall rules on C2 server
- Ensure SSH keys or passwords configured

### Q: Which pivot method is best?

**A:** Priority order: WireGuard (if configured) > AutoSSH > Chisel. WireGuard is fastest and most reliable.

---

## WiFi & Stealth

### Q: WiFi won't connect automatically

**A:**

- Add networks: `ghostctl wifi add "SSID" "password"`
- Set mode: `ghostctl wifi set auto`
- Reload: `ghostctl wifi reload`

### Q: Can GhostStick connect to enterprise WiFi?

**A:** WPA2-Enterprise not supported out of box. WPA-PSK (password-based) works fine.

### Q: How stealthy is GhostStick really?

**A:**

- Medium stealth blocks most casual detection
- High stealth suppresses beaconing and updates
- Still detectable by advanced EDR/XDR
- Physical USB insertion always leaves logs

### Q: Will antivirus detect it?

**A:**

- USB gadget itself: No
- HID payloads: Depends on what you're running
- Exfil volume: Encrypted, not scannable when locked
- Tools on device: May trigger AV if accessed

---

## Exfiltration Volume

### Q: How do I access the exfil volume?

**A:**

```bash
ghostctl exfil unlock    # Enter passphrase
ghostctl exfil mount
cd /opt/ghoststick/exfil
```

### Q: Forgot my exfil passphrase

**A:** Stored in `/opt/ghoststick/exfil.pass` (readable only by root). **Backup this file!**

### Q: Can host computer see the encrypted volume?

**A:** Only in "exfil" profile, it appears as USB mass storage (contents still encrypted).

### Q: How secure is the encryption?

**A:** LUKS2 with AES-256-XTS, Argon2id KDF, 512-bit keys. Very secure.

---

## Tools & Payloads

### Q: Which offensive tools are included?

**A:** Impacket, CrackMapExec, NetExec, Responder, Evil-WinRM, BloodHound, Chisel, Kerbrute, PEASS suite, ffuf.

### Q: How do I update tools?

**A:** `ghostctl update run` (runs full system update including tools)

### Q: Can I add my own tools?

**A:** Yes! Install normally or add to `50-tools-core.sh` for persistence.

### Q: Where are Responder/Impacket?

**A:**

- Responder: `/opt/responder/`
- Impacket: Available system-wide (via pip)
- PEASS: `/opt/peas/`

---

## Troubleshooting

### Q: GhostCTL command not found

**A:**

- Run: `sudo bash /opt/ghoststick/modules/95-ghostctl.sh`
- Or: `sudo bash install-ghostctl.sh`
- Or: Add to PATH manually

### Q: Services aren't starting

**A:**

```bash
sudo systemctl status ghoststick-gadget
sudo journalctl -u ghoststick-gadget -n 50
```

### Q: How do I reset to defaults?

**A:**

- Remove config: `sudo rm /opt/ghoststick/*.env`
- Rerun modules: `sudo bash /opt/ghoststick/modules/XX-*.sh`
- Or full reinstall

### Q: Installation logs location?

**A:** `/opt/ghoststick/install.log`

### Q: Complete diagnostics?

**A:** `ghostctl diag full`

---

## Security & Legal

### Q: Is GhostStick legal?

**A:** Legal for authorized penetration testing and research. Illegal to use on systems you don't own or have permission to test.

### Q: Can it be traced back to me?

**A:**

- MAC randomization helps but not foolproof
- USB insertion logs on host
- Network traffic potentially logged
- Use only in authorized scenarios

### Q: How do I securely wipe it?

**A:**

```bash
ghostctl seal apply        # Lock configuration
# Or complete wipe:
sudo bash uninstall.sh     # Option 3
```

### Q: What data persists on the device?

**A:**

- SSH keys (if generated)
- WiFi passwords
- Pivot credentials  
- Exfil passphrase
- HID payloads
- Tool outputs

---

## Advanced Usage

### Q: Can I chain multiple GhostSticks?

**A:** Theoretically yes, but not officially supported. Each needs unique USB configuration.

### Q: Remote management possible?

**A:** Via pivot tunnel + SSH. Set up AutoSSH reverse tunnel for persistent access.

### Q: Custom kernel for more gadgets?

**A:** Not included, but possible. Would need custom kernel compilation.

### Q: Can I boot from it?

**A:** No, GhostStick is not bootable. It's an implant device.

### Q: Battery power options?

**A:** Pi Zero can run on battery packs. Add external USB battery for portable operation.

---

## Contributing

### Q: How can I contribute?

**A:** See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Q: Found a bug, where to report?

**A:** GitHub Issues with details: OS version, Pi model, logs, steps to reproduce.

### Q: Want to add a feature

**A:** Open GitHub Discussion first to ensure alignment with project goals.

---

## Still Need Help?

- Check documentation: README.md, QUICKSTART.md, DEVELOPMENT.md
- Run diagnostics: `ghostctl diag full`
- Review logs: `/opt/ghoststick/install.log`
- GitHub Issues for bug reports
- GitHub Discussions for questions

**Remember**: Always use responsibly and legally. GhostStick is a powerful tool that requires careful handling.
