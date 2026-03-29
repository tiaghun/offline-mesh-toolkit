@echo off
REM ============================================================
REM  Flash Meshtastic Firmware to ESP32 Devices
REM  Works offline — uses locally cached firmware and esptool.
REM ============================================================
REM
REM  Supported devices: Heltec V3, T-Beam, T-Deck, T-Echo,
REM    Station G2, T-Beam Supreme, LILYGO T3S3, and more.
REM
REM  Usage: flash-esp32-meshtastic.bat [COM_PORT] [FIRMWARE_ZIP]
REM    COM_PORT:      e.g. COM3 (auto-detected if omitted)
REM    FIRMWARE_ZIP:  path to firmware zip (lists available if omitted)
REM ============================================================
setlocal enabledelayedexpansion

set "TOOLKIT_DIR=%~dp0.."
set "FW_DIR=%TOOLKIT_DIR%\meshtastic-firmware"
set "ESPTOOL_DIR=%TOOLKIT_DIR%\tools\esptool"
set "COM_PORT=%~1"
set "FW_ZIP=%~2"

echo ============================================================
echo   Flash Meshtastic — ESP32
echo ============================================================
echo.

REM --- Setup Python path ---
set "PYTHONPATH=%ESPTOOL_DIR%;%PYTHONPATH%"

REM --- Check esptool ---
python -c "import esptool" 2>nul
if %ERRORLEVEL% neq 0 (
    where esptool >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo ERROR: esptool not found.
        echo Run DOWNLOAD-ALL.bat first, or: pip install esptool
        pause
        exit /b 1
    )
)
echo esptool: OK
echo.

REM --- Auto-detect COM port if not specified ---
if "%COM_PORT%"=="" (
    echo Detecting serial ports...
    python -c "import serial.tools.list_ports; ports=[p for p in serial.tools.list_ports.comports()]; [print(f'  {p.device}: {p.description}') for p in ports]" 2>nul
    if %ERRORLEVEL% neq 0 (
        echo Could not auto-detect. Listing via MODE:
        mode | findstr "COM"
    )
    echo.
    set /p COM_PORT="Enter COM port (e.g. COM3): "
)

REM --- List or select firmware ---
if "%FW_ZIP%"=="" (
    echo.
    echo Available Meshtastic firmware files:
    echo.
    set "idx=0"
    for %%f in ("%FW_DIR%\firmware-*.zip") do (
        set /a idx+=1
        echo   !idx!. %%~nxf
        set "FW_!idx!=%%f"
    )
    if !idx!==0 (
        echo   No firmware files found in %FW_DIR%
        echo   Run DOWNLOAD-ALL.bat to download firmware.
        pause
        exit /b 1
    )
    echo.
    set /p CHOICE="Select firmware number: "
    set "FW_ZIP=!FW_%CHOICE%!"
)

if not exist "%FW_ZIP%" (
    echo ERROR: Firmware file not found: %FW_ZIP%
    pause
    exit /b 1
)

echo.
echo Selected firmware: %FW_ZIP%
echo Target port: %COM_PORT%
echo.

REM --- Extract firmware ---
set "EXTRACT_DIR=%TEMP%\meshtastic-flash-%RANDOM%"
echo Extracting firmware...
python -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "%FW_ZIP%" "%EXTRACT_DIR%"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to extract firmware.
    pause
    exit /b 1
)

REM --- Look for device-specific bin files ---
echo.
echo Extracted files:
dir /b "%EXTRACT_DIR%\*.bin" 2>nul
dir /b "%EXTRACT_DIR%\*.bin" /s 2>nul | findstr /i "." >nul
echo.

REM --- Flash ---
echo ============================================================
echo  FLASHING — Do not unplug the device!
echo ============================================================
echo.

REM Try to find the appropriate files
set "BOOTLOADER="
set "PARTITIONS="
set "APP="
set "MERGED="

for /r "%EXTRACT_DIR%" %%f in (*merged*.bin) do set "MERGED=%%f"
for /r "%EXTRACT_DIR%" %%f in (*bootloader*.bin) do set "BOOTLOADER=%%f"
for /r "%EXTRACT_DIR%" %%f in (*partitions*.bin) do set "PARTITIONS=%%f"
for /r "%EXTRACT_DIR%" %%f in (*firmware*.bin) do (
    echo %%~nxf | findstr /i /v "bootloader partitions merged" >nul && set "APP=%%f"
)

if defined MERGED (
    echo Flashing merged binary...
    python -m esptool --port %COM_PORT% --baud 921600 --chip auto write_flash 0x0 "%MERGED%"
) else if defined BOOTLOADER if defined APP (
    echo Flashing individual files...
    python -m esptool --port %COM_PORT% --baud 921600 --chip auto ^
        --before default_reset --after hard_reset write_flash ^
        0x1000 "%BOOTLOADER%" ^
        0x8000 "%PARTITIONS%" ^
        0x10000 "%APP%"
) else (
    echo ERROR: Could not identify firmware files to flash.
    echo Contents of extract directory:
    dir /b /s "%EXTRACT_DIR%"
    echo.
    echo Try manually: python -m esptool --port %COM_PORT% write_flash 0x0 [firmware.bin]
)

echo.
if %ERRORLEVEL% equ 0 (
    echo ============================================================
    echo   Flash complete! Device will reboot automatically.
    echo ============================================================
) else (
    echo ============================================================
    echo   Flash FAILED. Check connections and try again.
    echo   - Hold BOOT button while plugging in USB
    echo   - Try a different USB cable (data cable, not charge-only)
    echo   - Try a lower baud rate: change 921600 to 115200
    echo ============================================================
)

REM --- Cleanup ---
rmdir /s /q "%EXTRACT_DIR%" 2>nul

echo.
pause
