# test_main.ps1 - Debug-Version für DaydreamSMT
# Diese Version hat erweiterte Fehlerbehandlung und Debug-Ausgaben

param(
    [switch]$Debug = $false
)

# Fehlerbehandlung
$ErrorActionPreference = "Continue"
$VerbosePreference = if ($Debug) { "Continue" } else { "SilentlyContinue" }

# Konsole vorbereiten
if ($Debug) {
    $host.UI.RawUI.WindowTitle = "DaydreamSMT Debug Mode"
    Write-Host "=== DaydreamSMT Debug Mode ===" -ForegroundColor Green
    Write-Host ""
}

# Script-Pfade
$scriptPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $scriptPath) { $scriptPath = Get-Location }

Write-Verbose "Script path: $scriptPath"

# Log-Funktion
function Write-Log {
    param($Message, [switch]$IsError)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    
    if ($IsError) {
        Write-Host $logMessage -ForegroundColor Red
    } else {
        Write-Verbose $logMessage
    }
    
    # In Datei schreiben
    $logFile = Join-Path $scriptPath "debug.log"
    $logMessage | Add-Content $logFile
}

Write-Log "Starting DaydreamSMT..."
Write-Log "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Log "OS: $([System.Environment]::OSVersion.VersionString)"

try {
    # WPF prüfen und laden
    Write-Log "Loading WPF assemblies..."
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        Add-Type -AssemblyName PresentationCore -ErrorAction Stop
        Add-Type -AssemblyName WindowsBase -ErrorAction Stop
        Write-Log "WPF loaded successfully"
    } catch {
        throw "Failed to load WPF: $_"
    }
    
    # Module-Pfade prüfen
    $modulePath = Join-Path $scriptPath "GUI"
    Write-Log "Module path: $modulePath"
    
    if (-not (Test-Path $modulePath)) {
        throw "GUI module folder not found at: $modulePath"
    }
    
    # Module einzeln laden mit Fehlerbehandlung
    $modules = @(
        "WindowManager.psm1",
        "Components.psm1", 
        "PanelBuilder.psm1"
    )
    
    foreach ($module in $modules) {
        $moduleFile = Join-Path $modulePath $module
        Write-Log "Loading module: $module"
        
        if (-not (Test-Path $moduleFile)) {
            throw "Module file not found: $moduleFile"
        }
        
        try {
            Import-Module $moduleFile -Force -ErrorAction Stop
            Write-Log "Module loaded: $module"
        } catch {
            throw "Failed to load module $module : $_"
        }
    }
    
    # Pfade definieren
    $paths = @{
        Logo = Join-Path $scriptPath "logo.png"
        Tools = Join-Path $scriptPath "Tools"
        BIOS = Join-Path $scriptPath "BIOS"
        Images = Join-Path $scriptPath "IMAGES"
        Snapshot = Join-Path (Join-Path $scriptPath "Tools") "snapshot64.exe"
        GuidSet = Join-Path (Join-Path $scriptPath "Tools") "GUIDSET.EXE"
    }
    
    Write-Log "Configured paths:"
    $paths.GetEnumerator() | ForEach-Object { Write-Log "  $($_.Key): $($_.Value)" }
    
    # Verzeichnisse erstellen
    @($paths.Tools, $paths.BIOS, $paths.Images) | ForEach-Object {
        if (-not (Test-Path $_)) {
            Write-Log "Creating directory: $_"
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
    
    # Dummy-Logo erstellen falls nicht vorhanden
    if (-not (Test-Path $paths.Logo)) {
        Write-Log "Creating dummy logo"
        $dummyPng = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
        $bytes = [Convert]::FromBase64String($dummyPng)
        [System.IO.File]::WriteAllBytes($paths.Logo, $bytes)
    }
    
    # GUI erstellen
    Write-Log "Creating main window..."
    
    # Teste WindowManager Funktionen
    $functions = Get-Command -Module WindowManager -ErrorAction SilentlyContinue
    if (-not $functions) {
        throw "WindowManager module functions not available"
    }
    Write-Log "Available WindowManager functions: $($functions.Name -join ', ')"
    
    # Hauptfenster erstellen
    try {
        $window = New-MainWindow -LogoPath $paths.Logo
        Write-Log "Main window created"
    } catch {
        throw "Failed to create main window: $_"
    }
    
    # System Info Update
    try {
        Update-SystemInfo -Window $window
        Write-Log "System info updated"
    } catch {
        Write-Log "Failed to update system info: $_" -Error
        # Nicht kritisch, weitermachen
    }
    
    # Exit Buttons
    try {
        Setup-ExitButtons -Window $window
        Write-Log "Exit buttons configured"
    } catch {
        Write-Log "Failed to setup exit buttons: $_" -Error
    }
    
    # Panels holen
    $script:mainPanel = $window.FindName("MainButtonPanel")
    $script:submenuPanel = $window.FindName("SubmenuPanel")
    
    if (-not $script:mainPanel -or -not $script:submenuPanel) {
        throw "Failed to find main panels in window"
    }
    
    Write-Log "Adding main buttons..."
    
    # Error handler für Button clicks
    $buttonErrorHandler = {
        param($IsError)
        Write-Log "Button error: $error" -Error
        [System.Windows.MessageBox]::Show(
            "Error: $error", 
            "DaydreamSMT Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
    }
    
    # Buttons mit Try-Catch erstellen
    try {
        # CAPTURE
        $captureButton = New-StandardButton -Content "Capture" -ToolTip "Create system backup"
        $captureButton.Add_Click({
            try {
                Build-CapturePanel -SubmenuPanel $script:submenuPanel -MainPanel $script:mainPanel `
                    -SnapshotPath $paths.Snapshot -CaptureFolder $paths.Images
            } catch { & $buttonErrorHandler $_ }
        }.GetNewClosure())
        $script:mainPanel.Children.Add($captureButton)
        Write-Log "Capture button added"
    } catch {
        Write-Log "Failed to add Capture button: $_" -Error
    }
    
    try {
        # GUID
        $guidButton = New-StandardButton -Content "GUID" -ToolTip "Set BIOS ID"
        $guidButton.Add_Click({
            try {
                Build-GUIDPanel -GuidSetPath $paths.GuidSet -Window $window
            } catch { & $buttonErrorHandler $_ }
        }.GetNewClosure())
        $script:mainPanel.Children.Add($guidButton)
        Write-Log "GUID button added"
    } catch {
        Write-Log "Failed to add GUID button: $_" -Error
    }
    
    try {
        # FLASH
        $flashButton = New-StandardButton -Content "Flash" -ToolTip "Flash BIOS"
        $flashButton.Add_Click({
            try {
                Build-FlashPanel -SubmenuPanel $script:submenuPanel -MainPanel $script:mainPanel `
                    -BiosDir $paths.BIOS -Window $window
            } catch { & $buttonErrorHandler $_ }
        }.GetNewClosure())
        $script:mainPanel.Children.Add($flashButton)
        Write-Log "Flash button added"
    } catch {
        Write-Log "Failed to add Flash button: $_" -Error
    }
    
    try {
        # WIPE
        $wipeButton = New-StandardButton -Content "Wipe" -ToolTip "Wipe disk"
        $wipeButton.Add_Click({
            try {
                Build-WipePanel -SubmenuPanel $script:submenuPanel -MainPanel $script:mainPanel
            } catch { & $buttonErrorHandler $_ }
        }.GetNewClosure())
        $script:mainPanel.Children.Add($wipeButton)
        Write-Log "Wipe button added"
    } catch {
        Write-Log "Failed to add Wipe button: $_" -Error
    }
    
    try {
        # RESTORE  
        $restoreButton = New-StandardButton -Content "Restore" -ToolTip "Restore backup"
        $restoreButton.Add_Click({
            try {
                Build-RestorePanel -SubmenuPanel $script:submenuPanel -MainPanel $script:mainPanel `
                    -CaptureFolder $paths.Images -SnapshotPath $paths.Snapshot
            } catch { & $buttonErrorHandler $_ }
        }.GetNewClosure())
        $script:mainPanel.Children.Add($restoreButton)
        Write-Log "Restore button added"
    } catch {
        Write-Log "Failed to add Restore button: $_" -Error
    }
    
    try {
        # CUSTOM
        $customButton = New-StandardButton -Content "Custom" -ToolTip "Custom tools"
        $customButton.Add_Click({
            try {
                Build-CustomPanel -SubmenuPanel $script:submenuPanel -MainPanel $script:mainPanel -BiosDir $paths.BIOS
            } catch { & $buttonErrorHandler $_ }
        }.GetNewClosure())
        $script:mainPanel.Children.Add($customButton)
        Write-Log "Custom button added"
    } catch {
        Write-Log "Failed to add Custom button: $_" -Error
    }
    
    Write-Log "GUI setup complete, showing window..."
    
    if ($Debug) {
        Write-Host ""
        Write-Host "Debug mode active - Check debug.log for details" -ForegroundColor Yellow
        Write-Host "Window will now open..." -ForegroundColor Green
        Write-Host ""
    }
    
    # Fenster anzeigen
    $window.ShowDialog() | Out-Null
    
} catch {
    $errorMsg = "Fatal Error: $_"
    Write-Log $errorMsg -Error
    
    # Erweiterte Fehlerinfo
    if ($_.Exception.InnerException) {
        Write-Log "Inner Exception: $($_.Exception.InnerException.Message)" -Error
    }
    if ($_.ScriptStackTrace) {
        Write-Log "Stack Trace:`n$($_.ScriptStackTrace)" -Error
    }
    
    # Fehler anzeigen
    if ($Debug) {
        Write-Host ""
        Write-Host "=== FATAL ERROR ===" -ForegroundColor Red
        Write-Host $errorMsg -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        try {
            [System.Windows.MessageBox]::Show(
                "$errorMsg`n`nCheck debug.log for details.",
                "DaydreamSMT Fatal Error",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            )
        } catch {
            Write-Host $errorMsg -ForegroundColor Red
        }
    }
}

Write-Log "Script ended"