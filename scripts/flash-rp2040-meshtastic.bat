@echo off
REM ============================================================
REM  Flash Meshtastic Firmware to RP2040 Devices
REM  Supports: Raspberry Pi Pico, RP2040-LoRa, Nano RP2040, etc.
REM ============================================================
REM
REM  RP2040 uses UF2 drag-and-drop flashing:
REM    1. Hold BOOTSEL button while plugging in USB
REM    2. A USB drive named "RPI-RP2" appears
REM    3. Copy the .uf2 firmware file to the drive
REM    4. Device reboots automatically
REM
REM  This script automates finding the drive and copying.
REM ============================================================
setlocal enabledelayedexpansion

set "TOOLKIT_DIR=%~dp0.."
set "FW_DIR=%TOOLKIT_DIR%\meshtastic-firmware"
set "FW_FILE=%~1"

echo ============================================================
echo   Flash Meshtastic — RP2040
echo ============================================================
echo.

REM --- Select firmware ---
if "%FW_FILE%"=="" (
    echo Available RP2040 firmware:
    echo.
    set "idx=0"
    for %%f in ("%FW_DIR%\*.uf2" "%FW_DIR%\*rp2040*" "%FW_DIR%\*pico*") do (
        set /a idx+=1
        echo   !idx!. %%~nxf
        set "FW_!idx!=%%f"
    )
    if !idx!==0 (
        echo   No RP2040 firmware found in %FW_DIR%
        echo   Run DOWNLOAD-ALL.bat to download firmware.
        pause
        exit /b 1
    )
    echo.
    set /p CHOICE="Select firmware number: "
    set "FW_FILE=!FW_%CHOICE%!"
)

if not exist "%FW_FILE%" (
    echo ERROR: File not found: %FW_FILE%
    pause
    exit /b 1
)

echo Selected: %FW_FILE%
echo.

REM --- Find RP2040 bootloader drive ---
echo Looking for RP2040 bootloader drive (RPI-RP2)...
echo.
echo If not found, hold BOOTSEL button while plugging in USB.
echo.

set "FOUND_DRIVE="
for %%d in (D E F G H I J K L) do (
    if exist "%%d:\INFO_UF2.TXT" (
        type "%%d:\INFO_UF2.TXT" 2>nul | findstr /i "RP2040 RPI Pico" >nul
        if !ERRORLEVEL! equ 0 (
            set "FOUND_DRIVE=%%d:"
            echo   Found RP2040 drive: %%d:\
        ) else (
            REM Could be another UF2 device, still show it
            echo   Found UF2 drive: %%d:\ (may not be RP2040)
            set "FOUND_DRIVE=%%d:"
        )
    )
)

if not defined FOUND_DRIVE (
    echo   No RP2040 bootloader drive detected!
    echo.
    echo   To enter bootloader mode:
    echo     1. Unplug the device
    echo     2. Hold the BOOTSEL button
    echo     3. Plug in USB while holding BOOTSEL
    echo     4. Release BOOTSEL after 1 second
    echo     5. A drive called "RPI-RP2" should appear
    echo     6. Run this script again
    pause
    exit /b 1
)

echo.
set /p CONFIRM="Copy firmware to %FOUND_DRIVE%\? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo Cancelled.
    pause
    exit /b 0
)

echo.
echo Copying firmware...
copy "%FW_FILE%" "%FOUND_DRIVE%\"

if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================================
    echo   Flash complete! Device will reboot automatically.
    echo ============================================================
) else (
    echo.
    echo ERROR: Copy failed. Try again or manually copy:
    echo   copy "%FW_FILE%" %FOUND_DRIVE%\
)

echo.
pause
