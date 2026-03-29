@echo off
REM ============================================================
REM  Install Flashing Tools from Local Cache (Offline)
REM  Run this on a machine that has the toolkit but no internet.
REM ============================================================
setlocal enabledelayedexpansion

set "TOOLKIT_DIR=%~dp0"
cd /d "%TOOLKIT_DIR%"

echo ============================================================
echo   Install Flashing Tools (Offline)
echo ============================================================
echo.

REM --- Check Python ---
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Python is required but not found.
    echo Install Python 3.8+ from the tools folder or python.org
    pause
    exit /b 1
)

echo Python found:
python --version
echo.

REM --- Install esptool from local cache ---
echo [1/2] Installing esptool from local cache...
if exist "%TOOLKIT_DIR%tools\esptool" (
    set "PYTHONPATH=%TOOLKIT_DIR%tools\esptool;%PYTHONPATH%"
    echo   Added to PYTHONPATH: %TOOLKIT_DIR%tools\esptool

    REM Verify it works
    python -c "import esptool; print('  esptool version:', esptool.__version__)" 2>nul
    if %ERRORLEVEL% neq 0 (
        echo   WARNING: esptool import failed. Try: pip install esptool
    ) else (
        echo   esptool: OK
    )
) else (
    echo   WARNING: esptool not found in tools folder.
    echo   Run DOWNLOAD-ALL.bat while online first.
)
echo.

REM --- Install adafruit-nrfutil from local cache ---
echo [2/2] Installing adafruit-nrfutil from local cache...
if exist "%TOOLKIT_DIR%tools\nrfutil" (
    set "PYTHONPATH=%TOOLKIT_DIR%tools\nrfutil;%PYTHONPATH%"
    echo   Added to PYTHONPATH: %TOOLKIT_DIR%tools\nrfutil

    python -c "import adafruit_nrfutil; print('  adafruit-nrfutil: OK')" 2>nul
    if %ERRORLEVEL% neq 0 (
        echo   WARNING: adafruit-nrfutil import failed.
        echo   For nRF52, you may need: pip install adafruit-nrfutil
    )
) else (
    echo   WARNING: adafruit-nrfutil not found in tools folder.
    echo   Run DOWNLOAD-ALL.bat while online first.
)
echo.

REM --- Set up PATH helper ---
echo Creating path helper script...
(
    echo @echo off
    echo REM Run this to set up tool paths for the current terminal session
    echo set "PYTHONPATH=%TOOLKIT_DIR%tools\esptool;%TOOLKIT_DIR%tools\nrfutil;%%PYTHONPATH%%"
    echo set "PATH=%TOOLKIT_DIR%tools\esptool;%TOOLKIT_DIR%tools\nrfutil;%%PATH%%"
    echo echo Tool paths configured for this session.
) > "%TOOLKIT_DIR%tools\setup-paths.bat"
echo   Created: tools\setup-paths.bat
echo.

echo ============================================================
echo   Installation Complete
echo ============================================================
echo.
echo To use tools in a new terminal, run:
echo   tools\setup-paths.bat
echo.
echo Then use the flash scripts to flash your devices.
echo.
pause
