# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability in GhostStick, please report it responsibly:

1. **Email**: Contact the project maintainer privately
2. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

3. **Response Time**: You can expect an initial response within 48 hours

## Security Considerations

GhostStick is an offensive security tool designed for:

- Authorized penetration testing
- Red team operations
- Security research

### Important Warnings

⚠️ **Legal Notice**: Use only on systems you own or have explicit written authorization to test

⚠️ **Operational Security**:

- GhostStick contains stealth features but is not invisible
- Modern EDR/XDR solutions may detect USB devices
- Always assess target environment before deployment

⚠️ **Data Protection**:

- Exfiltration volumes use strong encryption (LUKS2/Argon2id)
- Passphrases stored in plaintext at `/opt/ghoststick/exfil.pass`
- Factory seal mode prevents unauthorized reconfiguration

### Best Practices

1. **Change Default Credentials**: Update SSH passwords immediately
2. **Secure Pivot Hosts**: Use strong authentication for C2 servers
3. **Encrypt Communications**: Use WireGuard over AutoSSH when possible
4. **Wipe After Use**: Use factory seal or secure wipe procedures
5. **Physical Security**: Treat device like any credential - protect it

## Known Security Limitations

- **USB Detection**: Cannot defeat all USB blocking solutions
- **EDR Detection**: May be detected by advanced endpoint protection
- **Physical Access**: Device requires physical insertion
- **Network Monitoring**: Outbound tunnels may be detected/blocked

## Secure Deployment Checklist

- [ ] Default passwords changed
- [ ] Pivot credentials configured securely
- [ ] Stealth level appropriate for environment
- [ ] WiFi credentials stored securely
- [ ] Exfiltration passphrase is strong
- [ ] Operational profile matches target OS
- [ ] Physical device is secured/tracked
- [ ] Legal authorization documented
- [ ] Incident response plan prepared

## Disclosure Policy

We follow coordinated vulnerability disclosure:

1. Vulnerability reported privately
2. Issue confirmed and validated
3. Fix developed and tested
4. Security advisory published
5. CVE assigned if applicable
6. Public disclosure after fix released

## Security Updates

Security patches will be released as soon as possible after validation. Monitor:

- GitHub Security Advisories
- CHANGELOG.md for security fixes
- GitHub Releases for updates

---

**Remember**: GhostStick is a powerful offensive tool. Use responsibly and legally.
