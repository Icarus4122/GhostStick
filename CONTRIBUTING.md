# GhostStick Contributing Guide

Thank you for your interest in contributing to GhostStick!

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs
- Include system details (Pi model, OS version)
- Provide logs from `/opt/ghoststick/install.log`
- Include steps to reproduce

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/my-feature`
3. **Make your changes**
4. **Test thoroughly** on actual hardware
5. **Commit with clear messages**: `git commit -m "Add feature: description"`
6. **Push to your fork**: `git push origin feature/my-feature`
7. **Open a Pull Request**

## Code Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Add `set -euo pipefail` for safety
- Follow existing naming conventions
- Add comments for complex logic
- Use shellcheck to validate
- Quote all variables: `"$VAR"` not `$VAR`

### Installation Modules

- Implement state checking for resume capability
- Create `.done` files in `/opt/ghoststick/state/`
- Use consistent error handling
- Log important actions
- Support both online and offline operation where possible

### GhostCTL Modules

- Export functions as `mod_<action>`
- Use helper functions: `ok`, `warn`, `err`, `info`, `confirm`
- Keep functions focused and simple
- Provide clear error messages
- Return appropriate exit codes

### Documentation

- Update README.md for user-facing features
- Update DEVELOPMENT.md for technical changes
- Add examples where helpful
- Keep language clear and concise

## Testing

- Test on Raspberry Pi Zero/Zero 2 W
- Test on Raspberry Pi 4/5 if possible
- Verify both fresh installs and updates
- Test resume capability (interrupt installer)
- Check all GhostCTL commands work
- Verify USB gadget functions on target hosts

## Module Development

### Adding New Installation Module

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "[XX] Module Name — Description"

GS="/opt/ghoststick"
STATE="$GS/state"
mkdir -p "$STATE"

# Resume-safe check
if [ -f "$STATE/mymodule.done" ]; then
    echo "[XX] Module already completed."
    exit 0
fi
touch "$STATE/mymodule.start"

# Your installation logic here

# Mark complete
touch "$STATE/mymodule.done"
echo "[XX] Module complete."
```

### Adding New GhostCTL Module

```bash
#!/bin/bash
# GhostCTL MyModule Module

mod_status() {
    info "Module Status"
    # Show current state
}

mod_enable() {
    ok "Feature enabled"
}

mod_disable() {
    warn "Feature disabled"
}
```

## Pull Request Guidelines

- Keep changes focused (one feature/fix per PR)
- Include clear description of changes
- Reference any related issues
- Update documentation as needed
- Ensure all shellcheck warnings are resolved
- Test on actual hardware before submitting

## Code Review Process

1. Maintainer reviews code
2. Feedback provided via PR comments
3. Updates made as needed
4. Approved PRs merged to main branch
5. Changes released in next version

## Questions?

- Open a GitHub Discussion
- Ask in Pull Request comments
- Check existing Issues and Documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make GhostStick better!
