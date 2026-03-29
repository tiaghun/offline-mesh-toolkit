# Contributing to Offline Mesh Firmware Toolkit

Thanks for your interest in contributing! This toolkit is meant to be community-driven — the more devices and scenarios we cover, the more useful it is for everyone.

## How to Contribute

### Report Issues
- Device not working with a flash script? Open an issue with your device model, OS, and error output.
- Missing a device? Let us know which one and we'll add support.

### Add Device Support
1. Fork the repo
2. Add or update the appropriate flash script in `scripts/`
3. Update the device lookup table in `README.md`
4. Test on your actual device if possible
5. Submit a pull request

### Improve Flash Scripts
- Better error messages and recovery suggestions
- New platform support (macOS-specific, ARM Linux, etc.)
- Auto-detection improvements

### Add Firmware Sources
Know of another mesh firmware project? Add download support:
1. Add the repo to `DOWNLOAD-ALL.bat`
2. Create flash scripts if the flashing process differs
3. Document it in the README

## Guidelines

- **Keep it simple** — These scripts run in emergencies. Clarity over cleverness.
- **Test on real hardware** when possible. Note which device you tested on in your PR.
- **Windows-first** — `.bat` scripts are primary. `.sh` scripts are backups.
- **No internet assumptions** — Flash scripts must work fully offline.
- **No external dependencies at flash time** — Everything needed must be in the toolkit after download.

## Code Style

- Batch scripts: use `REM` comments, `setlocal enabledelayedexpansion`, clear echo output
- Shell scripts: use `set -e`, comment sections, POSIX-compatible where possible
- Python: standard library only (no pip dependencies in the download helper)

## Testing Checklist

Before submitting a PR, verify:
- [ ] `DOWNLOAD-ALL.bat` still runs without errors
- [ ] Flash scripts detect the correct firmware files
- [ ] New devices are documented in the README device table
- [ ] Scripts handle missing files/tools gracefully with clear error messages
