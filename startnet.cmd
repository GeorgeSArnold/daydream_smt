::===============================================
:: startnet.cmd - Windows PE Startup Script
:: Ort: X:\Windows\System32\startnet.cmd
::===============================================
@echo off

:: Netzwerk initialisieren
wpeinit

:: Warten bis WinPE vollständig geladen ist
echo Initializing Windows PE...
timeout /t 3 /nobreak > nul

:: PowerShell Execution Policy setzen
powershell -Command "Set-ExecutionPolicy Bypass -Force" > nul 2>&1

:: Laufwerk mit Tool ermitteln (sucht nach main.ps1)
echo Looking for System Management Tool...
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\SystemManagementTool\main.ps1" (
        set TOOL_DRIVE=%%D:
        goto :FOUND
    )
)

:: Falls nicht gefunden, auf USB suchen
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\main.ps1" (
        set TOOL_DRIVE=%%D:
        goto :FOUND
    )
)

:NOT_FOUND
echo System Management Tool not found!
echo Please ensure the tool is on a connected drive.
echo.
echo Press any key to open command prompt...
pause > nul
cmd.exe
goto :END

:FOUND
echo Found System Management Tool on %TOOL_DRIVE%
cd /d %TOOL_DRIVE%\

:: Tool starten
if exist "%TOOL_DRIVE%\SystemManagementTool\main.ps1" (
    cd /d "%TOOL_DRIVE%\SystemManagementTool"
    echo Starting System Management Tool...
    powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "main.ps1"
) else (
    echo Starting System Management Tool...
    powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "main.ps1"
)

:: Falls Tool beendet wurde, CMD öffnen
cmd.exe

:END

::===============================================
:: ALTERNATIVE: winpeshl.ini
:: Ort: X:\Windows\System32\winpeshl.ini
:: Diese Datei startet Programme vor startnet.cmd
::===============================================
[LaunchApps]
%SYSTEMDRIVE%\Windows\System32\startnet.cmd

::===============================================
:: ALTERNATIVE 2: Unattend.xml für WinPE
:: Ort: X:\Windows\System32\unattend.xml
::===============================================
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Path>cmd /c "powershell -ExecutionPolicy Bypass -File X:\SystemManagementTool\main.ps1"</Path>
                    <Description>Start System Management Tool</Description>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
</unattend>

::===============================================
:: BATCH WRAPPER: start_tool.bat
:: Alternative für direkten Start
:: Ort: Auf USB/DVD Root oder X:\
::===============================================
@echo off
title System Management Tool
color 0F

:: PowerShell Check
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: PowerShell not found!
    echo This tool requires PowerShell to run.
    pause
    exit /b 1
)

:: Tool-Pfad suchen
if exist "%~dp0SystemManagementTool\main.ps1" (
    set TOOL_PATH=%~dp0SystemManagementTool
) else if exist "%~dp0main.ps1" (
    set TOOL_PATH=%~dp0
) else (
    echo ERROR: main.ps1 not found!
    echo Please check the installation.
    pause
    exit /b 1
)

:: Tool starten
echo ===============================================
echo     Windows PE System Management Tool
echo ===============================================
echo.
echo Starting GUI...
echo.

cd /d "%TOOL_PATH%"
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "main.ps1"

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Tool failed to start!
    echo Error Code: %errorlevel%
    echo.
    echo Check the log file: %TOOL_PATH%\startup.log
    pause
)

:: Nach Beendigung
echo.
echo Tool closed. Press any key to exit...
pause > nul
exit