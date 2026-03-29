@echo off
REM ============================================================
REM  Flash MeshCore Firmware to nRF52 Devices
REM  Supports: RAK4631, T-Echo, other nRF52840-based boards
REM ============================================================
setlocal enabledelayedexpansion

set "TOOLKIT_DIR=%~dp0.."
set "FW_DIR=%TOOLKIT_DIR%\meshcore-firmware"
set "NRFUTIL_DIR=%TOOLKIT_DIR%\tools\nrfutil"
set "COM_PORT=%~1"
set "FW_FILE=%~2"

echo ============================================================
echo   Flash MeshCore — nRF52 (RAK4631, T-Echo, etc.)
echo ============================================================
echo.
echo NOTE: nRF52 devices support UF2 drag-and-drop:
echo   1. Double-tap RESET to enter bootloader
echo   2. Drag .uf2 file onto the USB drive
echo   3. Device reboots automatically
echo.

REM --- Setup Python path ---
set "PYTHONPATH=%NRFUTIL_DIR%;%PYTHONPATH%"

REM --- List firmware ---
if "%FW_FILE%"=="" (
    echo Available MeshCore nRF52 firmware:
    echo.
    set "idx=0"
    for %%f in ("%FW_DIR%\*rak*" "%FW_DIR%\*nrf*" "%FW_DIR%\*.uf2") do (
        set /a idx+=1
        echo   !idx!. %%~nxf
        set "FW_!idx!=%%f"
    )
    if !idx!==0 (
        echo   No nRF52 firmware found in %FW_DIR%
        echo   Place .uf2 or .zip firmware files in that folder.
        pause
        exit /b 1
    )
    echo.
    set /p CHOICE="Select firmware number: "
    set "FW_FILE=!FW_%CHOICE%!"
)

REM --- Check if UF2 ---
echo %FW_FILE% | findstr /i ".uf2" >nul
if %ERRORLEVEL% equ 0 (
    echo UF2 file detected. Looking for bootloader drive...
    for %%d in (D E F G H I J K) do (
        if exist "%%d:\INFO_UF2.TXT" (
            echo   Found: %%d:\
            set /p CONFIRM="Copy firmware to %%d:\? (y/n): "
            if /i "!CONFIRM!"=="y" (
                copy "%FW_FILE%" "%%d:\"
                echo Done! Device will reboot.
            )
            goto :done
        )
    )
    echo   No UF2 drive found. Double-tap RESET on your device.
    goto :done
)

REM --- DFU flash ---
if "%COM_PORT%"=="" (
    python -c "import serial.tools.list_ports; [print(f'  {p.device}: {p.description}') for p in serial.tools.list_ports.comports()]" 2>nul
    echo.
    set /p COM_PORT="Enter COM port: "
)

echo Flashing via DFU...
python -m adafruit_nrfutil dfu serial --package "%FW_FILE%" -p %COM_PORT% -b 115200

if %ERRORLEVEL% equ 0 (
    echo Flash complete!
) else (
    echo Flash failed. Use UF2 drag-and-drop instead.
)

:done
echo.
pause
