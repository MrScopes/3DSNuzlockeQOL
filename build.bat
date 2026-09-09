@echo off
setlocal EnableExtensions

cd /d "%~dp0"

set "DEVKITPRO=C:\devkitPro"
set "BASH=%DEVKITPRO%\msys2\usr\bin\bash.exe"
set "BUILD=%~dp0build"

if not exist "%BASH%" (
    echo.
    echo ERROR: Could not find devkitPro MSYS2 Bash at:
    echo   %BASH%
    echo.
    echo If devkitPro is installed somewhere else, edit DEVKITPRO at the top of build.bat.
    echo.
    pause
    exit /b 1
)

if not exist "%DEVKITPRO%\devkitARM\bin\arm-none-eabi-gcc.exe" (
    echo.
    echo ERROR: devkitARM was not found under:
    echo   %DEVKITPRO%\devkitARM
    echo.
    pause
    exit /b 1
)

if not exist "%DEVKITPRO%\devkitARM\bin\arm-none-eabi-g++.exe" (
    echo.
    echo ERROR: The devkitARM C++ compiler was not found:
    echo   %DEVKITPRO%\devkitARM\bin\arm-none-eabi-g++.exe
    echo.
    pause
    exit /b 1
)

if not exist "%~dp0Games\*.mk" (
    echo.
    echo ERROR: No game configuration files were found under:
    echo   %~dp0Games
    echo.
    pause
    exit /b 1
)

echo ============================================================
echo   3DSNuzlockeQOL - Full Build
echo ============================================================
echo.
echo Project: %CD%
echo Output:  %BUILD%
echo.

rem The Makefile automatically discovers every Games\*.mk config.
"%BASH%" -lc "export DEVKITPRO=/opt/devkitpro; export DEVKITARM=/opt/devkitpro/devkitARM; cd \"$(cygpath -u '%CD%')\" && make clean && make all"

if errorlevel 1 goto :failed

rem Create the release ZIP using Windows PowerShell.
if exist "%BUILD%\3DSNuzlockeQOL-Azahar.zip" (
    del /f /q "%BUILD%\3DSNuzlockeQOL-Azahar.zip"
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "Compress-Archive -Path '%BUILD%\sdmc' -DestinationPath '%BUILD%\3DSNuzlockeQOL-Azahar.zip' -Force"

if errorlevel 1 goto :failed

rem ============================================================
rem Cleanup temporary compiler/linker artifacts
rem ============================================================

echo Cleaning temporary build artifacts...

for /r "%~dp0" %%F in (*.lst *.elf *.o *.d) do (
    del /f /q "%%F" >nul 2>&1
)

if exist "%BUILD%\obj" (
    rd /s /q "%BUILD%\obj"
)

rem Remove any empty directories under build\bin, regardless of game name.
if exist "%BUILD%\bin" (
    for /f "delims=" %%D in ('dir "%BUILD%\bin" /ad /b /s 2^>nul ^| sort /r') do (
        rd "%%D" >nul 2>&1
    )
)

echo.
echo ============================================================
echo   BUILD COMPLETE
echo ============================================================
echo.
echo Raw binaries:
if exist "%BUILD%\bin\*.3gx" (
    for %%F in ("%BUILD%\bin\*.3gx") do echo   build\bin\%%~nxF
) else (
    echo   [none]
)

echo.
echo Azahar title folders:
if exist "%BUILD%\sdmc\luma\plugins" (
    for /d %%D in ("%BUILD%\sdmc\luma\plugins\*") do echo   %%~nxD
) else (
    echo   [none]
)

echo.
echo Release ZIP:
echo   build\3DSNuzlockeQOL-Azahar.zip
echo.
echo Temporary compiler artifacts cleaned.
echo.
pause
exit /b 0

:failed
echo.
echo ============================================================
echo   BUILD FAILED
echo ============================================================
echo.
echo Check the error above.
echo.
pause
exit /b 1
