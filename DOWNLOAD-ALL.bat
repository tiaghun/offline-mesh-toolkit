@echo off
REM ============================================================
REM  OFFLINE MESH FIRMWARE TOOLKIT — Download Everything
REM  Run this ONCE while you have internet access.
REM  After this, you can flash devices completely offline.
REM ============================================================
setlocal enabledelayedexpansion

set "TOOLKIT_DIR=%~dp0"
cd /d "%TOOLKIT_DIR%"

echo ============================================================
echo   OFFLINE MESH FIRMWARE TOOLKIT — Download All
echo ============================================================
echo.
echo This script downloads all firmware and tools needed to flash
echo Meshtastic and MeshCore devices while offline.
echo.
echo Prerequisites: Python 3.8+ must be installed.
echo.

REM --- Check Python ---
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Python not found. Install Python 3.8+ from https://python.org
    echo Make sure "Add Python to PATH" is checked during install.
    pause
    exit /b 1
)

python --version
echo.

REM --- Optional: GitHub token for higher rate limits ---
if defined GITHUB_TOKEN (
    echo GitHub token detected — using authenticated requests.
) else (
    echo TIP: Set GITHUB_TOKEN env var to avoid rate limits.
    echo   set GITHUB_TOKEN=ghp_your_token_here
)
echo.

REM ============================================================
REM  1. DOWNLOAD MESHTASTIC FIRMWARE
REM ============================================================
echo [1/5] Downloading Meshtastic firmware (latest release)...
echo.
python "%TOOLKIT_DIR%download_github_release.py" meshtastic/firmware ^
    --output "%TOOLKIT_DIR%meshtastic-firmware" ^
    --pattern "firmware-*.zip"
if %ERRORLEVEL% neq 0 (
    echo WARNING: Meshtastic firmware download had errors.
)
echo.

REM Also grab the UF2 files for RP2040 devices
python "%TOOLKIT_DIR%download_github_release.py" meshtastic/firmware ^
    --output "%TOOLKIT_DIR%meshtastic-firmware" ^
    --pattern "firmware-rak4631-*.uf2"
echo.

REM ============================================================
REM  2. DOWNLOAD MESHCORE FIRMWARE
REM ============================================================
echo [2/5] Downloading MeshCore firmware (latest release)...
echo.

REM Try official MeshCore firmware repo
python "%TOOLKIT_DIR%download_github_release.py" meshcore-dev/meshcore ^
    --output "%TOOLKIT_DIR%meshcore-firmware" 2>nul
if %ERRORLEVEL% neq 0 (
    echo NOTE: Could not find meshcore-dev/meshcore.
    echo Trying alternative MeshCore repos...
    python "%TOOLKIT_DIR%download_github_release.py" aardzhanov/meshcore-firmware ^
        --output "%TOOLKIT_DIR%meshcore-firmware" 2>nul
)
echo.

REM ============================================================
REM  3. DOWNLOAD ESPTOOL (for ESP32 flashing)
REM ============================================================
echo [3/5] Downloading esptool...
echo.
if not exist "%TOOLKIT_DIR%tools\esptool" mkdir "%TOOLKIT_DIR%tools\esptool"

REM Install esptool via pip to a local directory
pip install --target="%TOOLKIT_DIR%tools\esptool" esptool 2>nul
if %ERRORLEVEL% neq 0 (
    echo Trying pip3...
    pip3 install --target="%TOOLKIT_DIR%tools\esptool" esptool 2>nul
)
if %ERRORLEVEL% neq 0 (
    echo WARNING: Could not install esptool via pip.
    echo You may need to install it manually: pip install esptool
)
echo.

REM ============================================================
REM  4. DOWNLOAD ADAFRUIT-NRFUTIL (for nRF52 flashing)
REM ============================================================
echo [4/5] Downloading adafruit-nrfutil...
echo.
if not exist "%TOOLKIT_DIR%tools\nrfutil" mkdir "%TOOLKIT_DIR%tools\nrfutil"

pip install --target="%TOOLKIT_DIR%tools\nrfutil" adafruit-nrfutil 2>nul
if %ERRORLEVEL% neq 0 (
    pip3 install --target="%TOOLKIT_DIR%tools\nrfutil" adafruit-nrfutil 2>nul
)
if %ERRORLEVEL% neq 0 (
    echo WARNING: Could not install adafruit-nrfutil via pip.
    echo For nRF52 devices, install manually: pip install adafruit-nrfutil
)
echo.

REM ============================================================
REM  5. DOWNLOAD UF2CONV (for RP2040 flashing)
REM ============================================================
echo [5/5] Downloading uf2conv.py for RP2040...
echo.
if not exist "%TOOLKIT_DIR%tools\uf2conv" mkdir "%TOOLKIT_DIR%tools\uf2conv"

REM Download uf2conv.py from Microsoft's uf2 repo
python -c "import urllib.request; urllib.request.urlretrieve('https://raw.githubusercontent.com/microsoft/uf2/master/utils/uf2conv.py', r'%TOOLKIT_DIR%tools\uf2conv\uf2conv.py')" 2>nul
if %ERRORLEVEL% neq 0 (
    echo WARNING: Could not download uf2conv.py
    echo RP2040 devices use drag-and-drop UF2 — this tool is optional.
)
echo.

REM ============================================================
REM  SUMMARY
REM ============================================================
echo ============================================================
echo   DOWNLOAD COMPLETE
echo ============================================================
echo.
echo Checking downloaded files...
echo.

echo --- Meshtastic Firmware ---
if exist "%TOOLKIT_DIR%meshtastic-firmware" (
    dir /b "%TOOLKIT_DIR%meshtastic-firmware\*.zip" 2>nul | findstr /v ".gitkeep" | find /c /v "" > "%TEMP%\count.tmp"
    set /p MCOUNT=<"%TEMP%\count.tmp"
    if "%MCOUNT%" == "0" (
		echo	WARNING: No firmware downloaded
	) else (
		echo   Found !MCOUNT! firmware files
	)
) else (
    echo   WARNING: No firmware downloaded
)

echo.
echo --- MeshCore Firmware ---
if exist "%TOOLKIT_DIR%meshcore-firmware" (
    dir /b "%TOOLKIT_DIR%meshcore-firmware\*" 2>nul | findstr /v ".gitkeep" | find /c /v "" > "%TEMP%\count.tmp"
    set /p CCOUNT=<"%TEMP%\count.tmp"
    if "%CCOUNT%" == "0" (
		echo	WARNING: No firmware downloaded
	) else (
		echo   Found !CCOUNT! firmware files
	)
) else (
    echo   WARNING: No firmware downloaded
)

echo.
echo --- Tools ---
if exist "%TOOLKIT_DIR%tools\esptool" (
    echo   esptool: OK
) else (
    echo   esptool: MISSING
)
if exist "%TOOLKIT_DIR%tools\nrfutil" (
    echo   adafruit-nrfutil: OK
) else (
    echo   adafruit-nrfutil: MISSING
)
if exist "%TOOLKIT_DIR%tools\uf2conv\uf2conv.py" (
    echo   uf2conv: OK
) else (
    echo   uf2conv: MISSING (optional for RP2040)
)

echo.
echo ============================================================
echo You can now flash devices OFFLINE using the flash scripts!
echo See README.md for device-specific instructions.
echo ============================================================
echo.
pause
