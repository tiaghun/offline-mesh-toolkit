@echo off
REM ============================================================
REM  Flash MeshCore Firmware to ESP32 Devices
REM  Works offline — uses locally cached firmware and esptool.
REM ============================================================
REM
REM  Usage: flash-esp32-meshcore.bat [COM_PORT] [FIRMWARE_FILE]
REM ============================================================
setlocal enabledelayedexpansion

set "TOOLKIT_DIR=%~dp0.."
set "FW_DIR=%TOOLKIT_DIR%\meshcore-firmware"
set "ESPTOOL_DIR=%TOOLKIT_DIR%\tools\esptool"
set "COM_PORT=%~1"
set "FW_FILE=%~2"

echo ============================================================
echo   Flash MeshCore — ESP32
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

REM --- Auto-detect COM port ---
if "%COM_PORT%"=="" (
    echo Detecting serial ports...
    python -c "import serial.tools.list_ports; ports=[p for p in serial.tools.list_ports.comports()]; [print(f'  {p.device}: {p.description}') for p in ports]" 2>nul
    echo.
    set /p COM_PORT="Enter COM port (e.g. COM3): "
)

REM --- List or select firmware ---
if "%FW_FILE%"=="" (
    echo.
    echo Available MeshCore firmware files:
    echo.
    set "idx=0"
    for %%f in ("%FW_DIR%\*.bin" "%FW_DIR%\*.zip") do (
        set /a idx+=1
        echo   !idx!. %%~nxf
        set "FW_!idx!=%%f"
    )
    if !idx!==0 (
        echo   No firmware files found in %FW_DIR%
        echo   Run DOWNLOAD-ALL.bat to download firmware.
        echo   Or manually place .bin files in: %FW_DIR%
        pause
        exit /b 1
    )
    echo.
    set /p CHOICE="Select firmware number: "
    set "FW_FILE=!FW_%CHOICE%!"
)

if not exist "%FW_FILE%" (
    echo ERROR: Firmware file not found: %FW_FILE%
    pause
    exit /b 1
)

echo.
echo Selected firmware: %FW_FILE%
echo Target port: %COM_PORT%
echo.

REM --- Handle zip files ---
set "FLASH_FILE=%FW_FILE%"
if "%FW_FILE:~-4%"==".zip" (
    set "EXTRACT_DIR=%TEMP%\meshcore-flash-%RANDOM%"
    echo Extracting firmware...
    python -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "%FW_FILE%" "!EXTRACT_DIR!"
    for /r "!EXTRACT_DIR!" %%f in (*.bin) do set "FLASH_FILE=%%f"
)

REM --- Flash ---
echo ============================================================
echo  FLASHING — Do not unplug the device!
echo ============================================================
echo.

REM Erase flash first for clean install
echo Step 1: Erasing flash...
python -m esptool --port %COM_PORT% --chip auto erase_flash
echo.

echo Step 2: Writing firmware...
python -m esptool --port %COM_PORT% --baud 921600 --chip auto write_flash 0x0 "%FLASH_FILE%"

echo.
if %ERRORLEVEL% equ 0 (
    echo ============================================================
    echo   Flash complete! Device will reboot.
    echo ============================================================
) else (
    echo ============================================================
    echo   Flash FAILED. Troubleshooting:
    echo   - Hold BOOT button while plugging in USB
    echo   - Try a different USB cable
    echo   - Try lower baud: change 921600 to 115200
    echo ============================================================
)

REM Cleanup
if defined EXTRACT_DIR rmdir /s /q "%EXTRACT_DIR%" 2>nul

echo.
pause
