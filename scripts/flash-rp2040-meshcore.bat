@echo off
REM ============================================================
REM  Flash MeshCore Firmware to RP2040 Devices
REM ============================================================
setlocal enabledelayedexpansion

set "TOOLKIT_DIR=%~dp0.."
set "FW_DIR=%TOOLKIT_DIR%\meshcore-firmware"
set "FW_FILE=%~1"

echo ============================================================
echo   Flash MeshCore — RP2040
echo ============================================================
echo.

REM --- Select firmware ---
if "%FW_FILE%"=="" (
    echo Available RP2040 MeshCore firmware:
    echo.
    set "idx=0"
    for %%f in ("%FW_DIR%\*.uf2" "%FW_DIR%\*rp2040*" "%FW_DIR%\*pico*") do (
        set /a idx+=1
        echo   !idx!. %%~nxf
        set "FW_!idx!=%%f"
    )
    if !idx!==0 (
        echo   No RP2040 firmware found in %FW_DIR%
        echo   Place .uf2 files in: %FW_DIR%
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

REM --- Find bootloader drive ---
echo Looking for RP2040 drive...
set "FOUND_DRIVE="
for %%d in (D E F G H I J K L) do (
    if exist "%%d:\INFO_UF2.TXT" (
        set "FOUND_DRIVE=%%d:"
        echo   Found: %%d:\
    )
)

if not defined FOUND_DRIVE (
    echo   No bootloader drive found!
    echo   Hold BOOTSEL while plugging in USB, then retry.
    pause
    exit /b 1
)

set /p CONFIRM="Copy firmware to %FOUND_DRIVE%\? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo Cancelled.
    pause
    exit /b 0
)

copy "%FW_FILE%" "%FOUND_DRIVE%\"
if %ERRORLEVEL% equ 0 (
    echo Flash complete! Device will reboot.
) else (
    echo Copy failed. Try manually.
)
echo.
pause
