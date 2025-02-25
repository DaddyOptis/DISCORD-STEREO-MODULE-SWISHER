@echo off
setlocal

set "GITHUB_FOLDER_URL=https://github.com/DaddyOptis/DISCORD-STEREO-MODULE-SWISHER/tree/main/stereo%%20%%2B%%20modules/discord_voice"
set "UPDATE_CHECK_URL=https://raw.githubusercontent.com/DaddyOptis/DISCORD-STEREO-MODULE-SWISHER/refs/heads/main/module-switcher.bat"
set "UPDATE_FILENAME=update.bat"
set "TEMP_FOLDER=%TEMP%\discord_voice_update"
set "DISCORD_PATH=%LOCALAPPDATA%\Discord"
set "MODULES_FOLDER=modules"
set "VOICE_MODULE_PREFIX=discord_voice-"

REM Check for updates before anything else
echo Checking for updates...
curl -s %UPDATE_CHECK_URL% > current_version.txt
if exist "%~dpnx0" (
    fc /b current_version.txt "%~nx0" >nul
    if errorlevel 1 (
        echo Update available. Downloading...
        curl -s %GITHUB_RAW_URL% -o "%UPDATE_FILENAME%"
        if exist "%UPDATE_FILENAME%" (
            start "" /wait "%UPDATE_FILENAME%"
            del "%~dpnx0"
            del current_version.txt
            exit
        ) else (
            echo Failed to download update.
            pause
            exit
        )
    ) else (
        echo No update available.
        del current_version.txt
    )
) else (
    echo Unable to check for updates.
    pause
    exit
)

REM Request admin privileges
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrator privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%TEMP%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%TEMP%\getadmin.vbs"
"%TEMP%\getadmin.vbs"
del "%TEMP%\getadmin.vbs"
exit /B

:gotAdmin
echo Administrator privileges granted.

REM Kill Discord
echo Killing Discord processes...
taskkill /f /im discord.exe >nul 2>&1

REM Construct the ZIP download URL
set "GITHUB_ZIP_URL=%GITHUB_FOLDER_URL:/tree/main/=/archive/main/%.zip"

REM Download the update ZIP
echo Downloading update files...
if not exist "%TEMP_FOLDER%" mkdir "%TEMP_FOLDER%"
curl -L -o "%TEMP_FOLDER%\discord_voice.zip" "%GITHUB_ZIP_URL%"

if not exist "%TEMP_FOLDER%\discord_voice.zip" (
    echo Failed to download update files.
    pause
    exit
)

REM Extract the update files
echo Extracting update files...
powershell -Command "Expand-Archive -Path '%TEMP_FOLDER%\discord_voice.zip' -DestinationPath '%TEMP_FOLDER%'"
if errorlevel 1 (
    echo Failed to extract update files.
    pause
    exit
)
del "%TEMP_FOLDER%\discord_voice.zip"

REM Find the latest Discord version
for /d %%a in ("%DISCORD_PATH%\app-*") do (
    set "LATEST_DISCORD_PATH=%%a"
)
if not defined LATEST_DISCORD_PATH (
    echo Discord not found.
    pause
    exit
)

REM Find the discord_voice module
for /d %%b in ("%LATEST_DISCORD_PATH%\%MODULES_FOLDER%\%VOICE_MODULE_PREFIX%*") do (
    set "VOICE_MODULE_PATH=%%b"
)
if not defined VOICE_MODULE_PATH (
    echo Discord voice module not found.
    pause
    exit
)

REM Replace the files
echo Replacing Discord voice module files...
for /r "%TEMP_FOLDER%\DISCORD-STEREO-MODULE-SWISHER-main\stereo  + modules\discord_voice" %%c in (*) do (
    if not "%%c"=="%TEMP_FOLDER%\DISCORD-STEREO-MODULE-SWISHER-main\stereo  + modules\discord_voice\discord_voice.zip" (
        if not "%%c"=="%TEMP_FOLDER%\DISCORD-STEREO-MODULE-SWISHER-main\stereo  + modules\discord_voice" (
            if exist "%VOICE_MODULE_PATH%\%%~nxC" (
                del "%VOICE_MODULE_PATH%\%%~nxC"
            )
            copy "%%c" "%VOICE_MODULE_PATH%\%%~nxC"
        )
    )
)

REM Clean up
echo Cleaning up...
rmdir /s /q "%TEMP_FOLDER%"

echo Update complete.
pause
exit /b
