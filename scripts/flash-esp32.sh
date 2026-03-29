#!/bin/bash
# ============================================================
#  Flash ESP32 Firmware (Linux/macOS backup script)
#  Works for both Meshtastic and MeshCore
# ============================================================
# Usage: ./flash-esp32.sh <firmware_file> [port]
# ============================================================

set -e

TOOLKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FW_FILE="$1"
PORT="${2:-/dev/ttyUSB0}"

if [ -z "$FW_FILE" ]; then
    echo "Usage: $0 <firmware_file> [serial_port]"
    echo ""
    echo "Available firmware:"
    ls -1 "$TOOLKIT_DIR"/meshtastic-firmware/*.{zip,bin} 2>/dev/null | sed 's/^/  /'
    ls -1 "$TOOLKIT_DIR"/meshcore-firmware/*.{zip,bin} 2>/dev/null | sed 's/^/  /'
    echo ""
    echo "Default port: /dev/ttyUSB0"
    exit 1
fi

# Add local esptool to path
export PYTHONPATH="$TOOLKIT_DIR/tools/esptool:$PYTHONPATH"

# Check esptool
if ! python3 -c "import esptool" 2>/dev/null && ! command -v esptool.py &>/dev/null; then
    echo "ERROR: esptool not found. Install: pip3 install esptool"
    exit 1
fi

# Auto-detect port
if [ ! -e "$PORT" ]; then
    echo "Port $PORT not found. Available ports:"
    ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | sed 's/^/  /'
    echo ""
    read -rp "Enter port: " PORT
fi

echo "Firmware: $FW_FILE"
echo "Port: $PORT"
echo ""

# Handle zip files
if [[ "$FW_FILE" == *.zip ]]; then
    EXTRACT_DIR=$(mktemp -d)
    echo "Extracting..."
    unzip -q "$FW_FILE" -d "$EXTRACT_DIR"

    # Look for merged binary first
    MERGED=$(find "$EXTRACT_DIR" -name "*merged*.bin" -print -quit)
    if [ -n "$MERGED" ]; then
        FW_FILE="$MERGED"
    else
        FW_FILE=$(find "$EXTRACT_DIR" -name "*.bin" ! -name "*bootloader*" ! -name "*partitions*" -print -quit)
    fi
    CLEANUP="$EXTRACT_DIR"
fi

# Flash
echo "Flashing..."
python3 -m esptool --port "$PORT" --baud 921600 --chip auto write_flash 0x0 "$FW_FILE"

echo ""
echo "Flash complete!"

# Cleanup
[ -n "$CLEANUP" ] && rm -rf "$CLEANUP"
