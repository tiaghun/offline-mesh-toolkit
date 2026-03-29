# Offline Mesh Firmware Toolkit

> Download once. Flash anywhere. No internet required.

A portable toolkit for flashing **Meshtastic** and **MeshCore** firmware to LoRa mesh devices — designed for field use, disaster response, and off-grid scenarios where internet access isn't available.

**Why this exists:** When you need to set up or recover mesh communication devices in the field — after a storm, during a wildfire evacuation, or deep in the backcountry — you can't count on having internet access. This toolkit lets you prepare everything in advance, throw it on a USB drive, and flash devices anywhere.

## Supported Platforms

| Platform | Status |
|----------|--------|
| Windows 10/11 | Primary — `.bat` scripts |
| Linux | Backup — `.sh` scripts |
| macOS | Backup — `.sh` scripts |

## Quick Start

### 1. Clone or Download

```bash
git clone https://github.com/YOUR_USERNAME/offline-mesh-toolkit.git
cd offline-mesh-toolkit
```

Or download the ZIP and extract it anywhere (USB drive works great).

### 2. Download Firmware + Tools (requires internet — do this ONCE)

**Windows:**
```
Double-click: DOWNLOAD-ALL.bat
```

**Linux/macOS:**
```bash
python3 download_github_release.py meshtastic/firmware -o meshtastic-firmware
pip3 install esptool adafruit-nrfutil
```

### 3. Flash Devices (works completely offline)

Run the appropriate script from the `scripts/` folder:

| Firmware | ESP32 | nRF52 | RP2040 |
|----------|-------|-------|--------|
| **Meshtastic** | `flash-esp32-meshtastic.bat` | `flash-nrf52-meshtastic.bat` | `flash-rp2040-meshtastic.bat` |
| **MeshCore** | `flash-esp32-meshcore.bat` | `flash-nrf52-meshcore.bat` | `flash-rp2040-meshcore.bat` |

Scripts auto-detect your device, list available firmware, and walk you through flashing.

---

## Device Lookup Table

Find your device, use the matching script.

### ESP32 Devices (Serial Flash via esptool)

| Device | Chip | Bootloader Entry |
|--------|------|-----------------|
| Heltec V3 | ESP32-S3 | Hold BOOT, plug USB |
| Heltec V2 | ESP32 | Hold BOOT, plug USB |
| LILYGO T-Beam | ESP32 | Hold BOOT, plug USB |
| LILYGO T-Beam Supreme | ESP32-S3 | Hold BOOT, plug USB |
| LILYGO T-Deck | ESP32-S3 | Hold BOOT, plug USB |
| LILYGO T3S3 | ESP32-S3 | Hold BOOT, plug USB |
| Station G2 | ESP32-S3 | Hold BOOT, plug USB |

### nRF52 Devices (UF2 Drag-and-Drop)

| Device | Chip | Bootloader Entry |
|--------|------|-----------------|
| RAK WisBlock (RAK4631) | nRF52840 | Double-tap RESET |
| LILYGO T-Echo | nRF52840 | Double-tap RESET |
| Nano G2 Ultra | nRF52840 | Double-tap RESET |

### RP2040 Devices (UF2 Drag-and-Drop)

| Device | Chip | Bootloader Entry |
|--------|------|-----------------|
| RP2040-LoRa | RP2040 | Hold BOOTSEL, plug USB |
| Raspberry Pi Pico + LoRa HAT | RP2040 | Hold BOOTSEL, plug USB |

### How to Identify Your Chip

- **ESP32/ESP32-S3**: Small BOOT button on board. Shows as COM port (Windows) or `/dev/ttyUSB0` (Linux).
- **nRF52840**: Has RESET button (not BOOT). Double-tap RESET = USB drive appears (e.g., "RAK4631").
- **RP2040**: Has BOOTSEL button. Hold while plugging USB = "RPI-RP2" drive appears.

---

## Emergency Reference Card

Print this. Keep it in your go-bag.

### ESP32 — Device Not Responding
```
1. Hold BOOT button
2. Plug in USB cable while holding BOOT
3. Release BOOT after 1 second
4. Run flash script within 10 seconds
5. Still failing? Try a different USB cable (must be DATA cable)
```

### nRF52 — Device Stuck
```
1. Double-tap RESET quickly (like double-clicking a mouse)
2. USB drive appears within 3 seconds
3. Drag .uf2 file onto the drive
4. No drive? Try different double-tap timing (faster/slower)
```

### RP2040 — Won't Enter Bootloader
```
1. Unplug USB
2. Hold BOOTSEL firmly
3. Plug USB while holding BOOTSEL
4. Release after 1 second
5. "RPI-RP2" drive should appear
```

### Troubleshooting Quick Reference

| Problem | Fix |
|---------|-----|
| No serial port found | Install USB driver — CP2102 (Silicon Labs) or CH340 (WCH) |
| Failed to connect | Hold BOOT + plug USB + release after 1s, then flash immediately |
| Permission denied (Linux) | `sudo usermod -a -G dialout $USER` then re-login |
| Timed out waiting for packet | Use lower baud rate: 115200 instead of 921600 |
| UF2 drive not appearing | Charge device via USB for 10 min, then try again |
| Wrong firmware flashed | Just re-flash with correct file — won't brick the device |
| Device in boot loop | Erase first: `python -m esptool --port COMx erase_flash` |

### USB Driver Downloads

| Chip | Driver |
|------|--------|
| CP2102 / CP2104 | Silicon Labs CP210x VCP — silabs.com |
| CH340 / CH9102 | WCH CH340 — wch-ic.com |
| FTDI FT232 | FTDI VCP — ftdichip.com |

---

## Folder Structure

```
offline-mesh-toolkit/
├── DOWNLOAD-ALL.bat              # One-click download (run while online)
├── install-tools-offline.bat     # Set up tools from local cache
├── download_github_release.py    # Python helper for GitHub downloads
├── README.md
├── LICENSE
├── meshtastic-firmware/          # Downloaded Meshtastic .zip/.bin/.uf2
├── meshcore-firmware/            # Downloaded MeshCore .bin/.uf2
├── tools/                        # esptool, nrfutil, uf2conv
│   ├── esptool/
│   ├── nrfutil/
│   └── uf2conv/
└── scripts/
    ├── flash-esp32-meshtastic.bat
    ├── flash-esp32-meshcore.bat
    ├── flash-nrf52-meshtastic.bat
    ├── flash-nrf52-meshcore.bat
    ├── flash-rp2040-meshtastic.bat
    ├── flash-rp2040-meshcore.bat
    ├── flash-esp32.sh            # Linux/macOS backups
    ├── flash-nrf52.sh
    └── flash-rp2040.sh
```

---

## Advanced Usage

### Download Specific Firmware Versions

```bash
# List available releases
python download_github_release.py meshtastic/firmware --list-releases

# Download a specific version
python download_github_release.py meshtastic/firmware --tag v2.5.6.0 -o meshtastic-firmware

# Download only UF2 files
python download_github_release.py meshtastic/firmware --pattern "*.uf2" -o meshtastic-firmware
```

### GitHub Rate Limits & Responsible Usage

This toolkit downloads firmware from public GitHub releases and tools from PyPI. We've reviewed the terms of service for all sources:

- **GitHub API**: Unauthenticated requests are limited to 60/hour. The download script makes ~10-20 requests, well within limits. It also skips files that are already downloaded and adds short delays between requests.
- **PyPI**: `pip install --target` for offline use is a fully supported, documented workflow.
- **Microsoft UF2 repo**: MIT licensed — downloading and redistributing `uf2conv.py` is explicitly allowed.

**Recommended:** Set a GitHub token for higher rate limits (5,000/hour) and to be a good citizen:

```bash
# Windows
set GITHUB_TOKEN=ghp_your_token_here

# Linux/macOS
export GITHUB_TOKEN=ghp_your_token_here
```

Create a personal access token at: Settings > Developer settings > Personal access tokens (no special scopes needed for public repos).

### Manual Firmware Download

If the scripts don't work for your setup:

1. **Meshtastic**: Go to github.com/meshtastic/firmware/releases — download the zip for your device
2. **MeshCore**: Check the MeshCore GitHub repos for latest releases
3. Place downloaded files in the appropriate firmware folder

---

## Prerequisites

- **Python 3.8+** — [python.org](https://python.org) (check "Add Python to PATH" during install)
- **USB data cable** — Charge-only cables don't carry data
- **USB drivers** — See driver table above (most modern OS install these automatically)

---

## Use Cases

- **Disaster response**: Pre-load USB drives with firmware for rapid mesh network deployment
- **Field operations**: Flash or recover devices at remote sites with no connectivity
- **Community events**: Set up flash stations at meetups, preparedness expos, or ham radio events
- **Bugout preparedness**: Keep a USB drive in your kit alongside your mesh radios
- **Workshop/training**: Standardized flashing setup for teaching mesh networking

---

## Related Projects

- [Meshtastic](https://meshtastic.org) — Open-source LoRa mesh networking
- [MeshCore](https://github.com/rocketgod-git/meshcore) — Alternative mesh firmware
- Bugout / emergency preparedness communities — if you're building comms kits, this pairs well with tools like NOMAD and similar field-deployable software suites

---

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Some ways to help:
- Add support for new devices
- Test on different OS versions
- Improve error handling in flash scripts
- Add firmware sources for other mesh projects
- Write translations for non-English users
- Share your field-tested deployment workflows

---

## License

[MIT](LICENSE) — Use it, fork it, put it on a USB drive, share it freely.
