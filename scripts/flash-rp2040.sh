#!/bin/bash
# ============================================================
#  Flash RP2040 Firmware (Linux/macOS backup script)
#  UF2 drag-and-drop method
# ============================================================
# Usage: ./flash-rp2040.sh <firmware.uf2>
# ============================================================

set -e

FW_FILE="$1"

if [ -z "$FW_FILE" ]; then
    echo "Usage: $0 <firmware.uf2>"
    echo ""
    echo "Steps:"
    echo "  1. Hold BOOTSEL while plugging in USB"
    echo "  2. Run this script with the .uf2 file"
    exit 1
fi

echo "Looking for RP2040 bootloader drive..."

# Common mount points
UF2_MOUNT=""
for dir in /media/$USER/RPI-RP2 /run/media/$USER/RPI-RP2 /Volumes/RPI-RP2; do
    if [ -d "$dir" ]; then
        UF2_MOUNT="$dir"
        break
    fi
done

# Fallback: search by INFO_UF2.TXT
if [ -z "$UF2_MOUNT" ]; then
    UF2_MOUNT=$(find /media /run/media /Volumes 2>/dev/null -name "INFO_UF2.TXT" -exec dirname {} \; | head -1)
fi

if [ -z "$UF2_MOUNT" ]; then
    echo "No RP2040 drive found!"
    echo "Hold BOOTSEL while plugging in USB, then retry."
    exit 1
fi

echo "Found: $UF2_MOUNT"
echo "Copying $FW_FILE..."
cp "$FW_FILE" "$UF2_MOUNT/"
sync
echo "Flash complete! Device will reboot."
