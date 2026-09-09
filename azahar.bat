@echo off
setlocal EnableExtensions

cd /d "%~dp0"

set "AZAHAR=%APPDATA%\Azahar"
set "SOURCE=%~dp0build\sdmc"
set "DEST=%AZAHAR%\sdmc"

echo ==========================================
echo   3DS Nuzlocke QOL - Azahar Installer
echo ==========================================
echo.

if not exist "%SOURCE%\luma\plugins" (
    echo ERROR: Built plugin files were not found.
    echo.
    echo Expected:
    echo   %SOURCE%\luma\plugins
    echo.
    echo Run build.bat first, or use a release/project ZIP that already includes build\sdmc.
    echo.
    pause
    exit /b 1
)

if not exist "%AZAHAR%" (
    echo ERROR: Azahar folder was not found:
    echo   %AZAHAR%
    echo.
    echo Start Azahar at least once, then try again.
    echo.
    pause
    exit /b 1
)

echo Installing to:
echo   %DEST%
echo.

if not exist "%DEST%" mkdir "%DEST%"

rem Merge only. /E does not delete unrelated plugins or files.
robocopy "%SOURCE%" "%DEST%" /E /R:2 /W:1
set "RC=%ERRORLEVEL%"

rem Robocopy exit codes 0-7 are successful.
if %RC% GEQ 8 (
    echo.
    echo ERROR: Copy failed. Robocopy exit code: %RC%
    echo.
    pause
    exit /b %RC%
)

echo.
echo ==========================================
echo   Installation complete!
echo ==========================================
echo.
echo Installed plugins under:
echo   %DEST%\luma\plugins
echo.
pause
exit /b 0
