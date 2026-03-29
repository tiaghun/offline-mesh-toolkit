#!/bin/bash
# ============================================================
#  Flash nRF52 Firmware (Linux/macOS backup script)
#  UF2 drag-and-drop or DFU over serial
# ============================================================
# Usage: ./flash-nrf52.sh <firmware_file> [port]
# ============================================================

set -e

TOOLKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FW_FILE="$1"
PORT="${2:-/dev/ttyACM0}"

if [ -z "$FW_FILE" ]; then
    echo "Usage: $0 <firmware_file> [serial_port]"
    echo ""
    echo "For UF2 files: Double-tap RESET, then copy to mounted drive"
    echo "For DFU packages: This script uses adafruit-nrfutil"
    exit 1
fi

export PYTHONPATH="$TOOLKIT_DIR/tools/nrfutil:$PYTHONPATH"

if [[ "$FW_FILE" == *.uf2 ]]; then
    echo "UF2 file detected."
    echo "Double-tap RESET on your device, then:"

    # Try to find mounted UF2 drive
    UF2_MOUNT=$(mount | grep -i "uf2\|rak4631\|rpi-rp2" | awk '{print $3}' | head -1)
    if [ -n "$UF2_MOUNT" ]; then
        echo "Found UF2 drive at: $UF2_MOUNT"
        read -rp "Copy firmware? (y/n): " CONFIRM
        if [ "$CONFIRM" = "y" ]; then
            cp "$FW_FILE" "$UF2_MOUNT/"
            sync
            echo "Done! Device will reboot."
        fi
    else
        echo "No UF2 drive found. After double-tap RESET:"
        echo "  cp \"$FW_FILE\" /media/\$USER/RAK4631/"
    fi
else
    echo "Flashing via DFU..."
    python3 -m adafruit_nrfutil dfu serial --package "$FW_FILE" -p "$PORT" -b 115200
    echo "Flash complete!"
fi
