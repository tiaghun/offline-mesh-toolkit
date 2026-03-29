@echo off
REM ============================================================
REM  Flash Meshtastic Firmware to nRF52 Devices
REM  Supports: RAK4631, T-Echo, other nRF52840-based boards
REM ============================================================
REM
REM  nRF52 devices use UF2 bootloader (drag-and-drop) or
REM  adafruit-nrfutil for DFU over serial.
REM
REM  Usage: flash-nrf52-meshtastic.bat [COM_PORT] [FIRMWARE_FILE]
REM ============================================================
setlocal enabledelayedexpansion

set "TOOLKIT_DIR=%~dp0.."
set "FW_DIR=%TOOLKIT_DIR%\meshtastic-firmware"
set "NRFUTIL_DIR=%TOOLKIT_DIR%\tools\nrfutil"
set "COM_PORT=%~1"
set "FW_FILE=%~2"

echo ============================================================
echo   Flash Meshtastic — nRF52 (RAK4631, T-Echo, etc.)
echo ============================================================
echo.
echo NOTE: Most nRF52 devices support UF2 drag-and-drop flashing:
echo   1. Double-tap RESET to enter bootloader (drive appears)
echo   2. Drag the .uf2 file onto the drive
echo   3. Device reboots automatically
echo.
echo This script uses adafruit-nrfutil for DFU over serial.
echo.

REM --- Setup Python path ---
set "PYTHONPATH=%NRFUTIL_DIR%;%PYTHONPATH%"

REM --- List firmware ---
if "%FW_FILE%"=="" (
    echo Available nRF52 firmware files:
    echo.
    set "idx=0"
    for %%f in ("%FW_DIR%\*rak4631*" "%FW_DIR%\*nrf52*" "%FW_DIR%\*t-echo*") do (
        set /a idx+=1
        echo   !idx!. %%~nxf
        set "FW_!idx!=%%f"
    )
    for %%f in ("%FW_DIR%\*.uf2") do (
        set /a idx+=1
        echo   !idx!. %%~nxf [UF2 - use drag-and-drop]
        set "FW_!idx!=%%f"
    )
    if !idx!==0 (
        echo   No nRF52 firmware files found.
        echo   Run DOWNLOAD-ALL.bat to download firmware.
        pause
        exit /b 1
    )
    echo.
    set /p CHOICE="Select firmware number: "
    set "FW_FILE=!FW_%CHOICE%!"
)

REM --- Check if UF2 file ---
echo %FW_FILE% | findstr /i ".uf2" >nul
if %ERRORLEVEL% equ 0 (
    echo.
    echo This is a UF2 file. Use drag-and-drop method:
    echo.
    echo   1. Double-tap RESET button on your device
    echo   2. A USB drive should appear (e.g. RAK4631, TECHOBOOT)
    echo   3. Copy the UF2 file to that drive:
    echo      copy "%FW_FILE%" [DRIVE_LETTER]:\
    echo   4. Device will reboot automatically
    echo.

    REM Try to find the UF2 drive
    echo Looking for UF2 bootloader drives...
    for %%d in (D E F G H I J K) do (
        if exist "%%d:\INFO_UF2.TXT" (
            echo   Found UF2 drive: %%d:\
            set /p CONFIRM="Copy firmware to %%d:\? (y/n): "
            if /i "!CONFIRM!"=="y" (
                copy "%FW_FILE%" "%%d:\"
                echo Firmware copied! Device will reboot.
            )
            goto :done
        )
    )
    echo   No UF2 drive detected. Double-tap RESET and try again.
    goto :done
)

REM --- DFU over serial ---
if "%COM_PORT%"=="" (
    echo Detecting serial ports...
    python -c "import serial.tools.list_ports; [print(f'  {p.device}: {p.description}') for p in serial.tools.list_ports.comports()]" 2>nul
    echo.
    set /p COM_PORT="Enter COM port (e.g. COM3): "
)

echo.
echo Flashing via DFU: %FW_FILE%
echo Port: %COM_PORT%
echo.

python -m adafruit_nrfutil dfu serial --package "%FW_FILE%" -p %COM_PORT% -b 115200

if %ERRORLEVEL% equ 0 (
    echo.
    echo Flash complete!
) else (
    echo.
    echo Flash failed. Try:
    echo   - Double-tap RESET to enter bootloader
    echo   - Use the UF2 drag-and-drop method instead
    echo   - Check USB cable and port
)

:done
echo.
pause
