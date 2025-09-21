# main.ps1 Daydream System Management Tool

# Fehlerbehandlung aktivieren
$ErrorActionPreference = "Stop"

# Script-Pfade
$scriptDirectory = "C:\PROJECTs\DaydreamSMT"
$toolsDir = Join-Path $scriptDirectory "Tools"
$snapshotPath = Join-Path $toolsDir "snapshot64.exe"
$biosDir = Join-Path $scriptDirectory "BIOS"
$captureFolder = Join-Path $scriptDirectory "IMAGES"
$guidSetPath = Join-Path $toolsDir "GUIDSET.EXE"
$logoFile = Join-Path $scriptDirectory "logo.png"

# Logging
$logFile = Join-Path $scriptDirectory "startup.log"
"[$(Get-Date)] Starting System Management Tool..." | Out-File $logFile

try {
    # WPF Assembly laden
    Add-Type -AssemblyName PresentationFramework
    "[$(Get-Date)] WPF loaded successfully" | Add-Content $logFile

    # Module laden
    Import-Module "$scriptDirectory\GUI\WindowManager.psm1" -Force
    Import-Module "$scriptDirectory\GUI\Components.psm1" -Force
    Import-Module "$scriptDirectory\GUI\PanelBuilder.psm1" -Force
    "[$(Get-Date)] Modules loaded successfully" | Add-Content $logFile

    # Verzeichnisse erstellen falls nicht vorhanden
    @($toolsDir, $biosDir, $captureFolder) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            "[$(Get-Date)] Created directory: $_" | Add-Content $logFile
        }
    }

    # Dummy-Logo erstellen falls nicht vorhanden
    if (-not (Test-Path $logoFile)) {
        "[$(Get-Date)] Logo not found, creating dummy" | Add-Content $logFile
        $dummyPngBytes = [Convert]::FromBase64String(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
        )
        [System.IO.File]::WriteAllBytes($logoFile, $dummyPngBytes)
    }

    # Hauptfenster erstellen
    "[$(Get-Date)] Creating main window" | Add-Content $logFile
    $window = New-MainWindow -LogoPath $logoFile
    Update-SystemInfo -Window $window
    Setup-ExitButtons -Window $window

    # Panels holen
    $script:mainPanel = $window.FindName("MainButtonPanel")
    $script:submenuPanel = $window.FindName("SubmenuPanel")

    "[$(Get-Date)] Adding main buttons" | Add-Content $logFile

    # PARTITION Button
    $captureButton = New-StandardButton -Content "Disk Management" -ToolTip "Open Disk Management" -ClickHandler {
        try { Start-Process diskmgmt.msc -Verb RunAs }
        catch { [System.Windows.MessageBox]::Show("Error: $_","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) }
    }
    $script:mainPanel.Children.Add($captureButton)

    # SNAPSHOT Button – direkt die EXE starten
    $snapButton = New-StandardButton -Content "SnapShot v1.50" -ToolTip "Install Windows 11 > Jetway/iBase Mainboards" -ClickHandler {
        try {
            if (Test-Path $snapshotPath) { Start-Process $snapshotPath -Verb RunAs }
            else { [System.Windows.MessageBox]::Show("Snapshot64.exe wurde nicht gefunden: $snapshotPath","Fehler",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) }
        } catch { [System.Windows.MessageBox]::Show("Fehler beim Starten: $_","Fehler",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) }
    }
    $script:mainPanel.Children.Add($snapButton)

    # GUID Button
    $guidButton = New-StandardButton -Content "set GUID" -ToolTip "Set UIID/GUID > Mainboard" -ClickHandler {
        try { Build-GUIDPanel -GuidSetPath $guidSetPath -Window $window }
        catch { [System.Windows.MessageBox]::Show("Error: $_","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) }
    }
    $script:mainPanel.Children.Add($guidButton)

    # # FILE Exporer Button
    # $flashButton = New-StandardButton -Content "Flash" -ToolTip "Flash BIOS ROM" -ClickHandler {
    #     try { Build-FlashPanel -SubmenuPanel $script:submenuPanel -MainPanel $script:mainPanel -BiosDir $biosDir -Window $window }
    #     catch { [System.Windows.MessageBox]::Show("Error: $_","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) }
    # }
    # $script:mainPanel.Children.Add($flashButton)

    # FILE Explorer Button
    $explorerButton = New-StandardButton -Content "File Explorer" -ToolTip "Open File Explorer at C:\" -ClickHandler {
    try { 
        Start-Process -FilePath "explorer.exe" -ArgumentList "C:\"
    }
    catch { 
        [System.Windows.MessageBox]::Show("Error opening File Explorer: $_","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) 
    }
    }
    $script:mainPanel.Children.Add($explorerButton)

    # # WIPE Button
    # $wipeButton = New-StandardButton -Content "Wipe" -ToolTip "Wipe Physical Disks" -ClickHandler {
    #     try { Build-WipePanel -SubmenuPanel $script:submenuPanel -MainPanel $script:mainPanel }
    #     catch { [System.Windows.MessageBox]::Show("Error: $_","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) }
    # }
    # $script:mainPanel.Children.Add($wipeButton)

    # # CUSTOM Button
    # $customButton = New-StandardButton -Content "Custom" -ToolTip "Custom Tools" -ClickHandler {
    #     try { Build-CustomPanel -SubmenuPanel $script:submenuPanel -MainPanel $script:mainPanel -BiosDir $biosDir }
    #     catch { [System.Windows.MessageBox]::Show("Error: $_","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) }
    # }
    # $script:mainPanel.Children.Add($customButton)

    "[$(Get-Date)] GUI setup complete, showing window" | Add-Content $logFile
    $window.ShowDialog() | Out-Null

} catch {
    $errorMsg = "Fatal Error: $_"
    $errorMsg | Add-Content $logFile
    try { [System.Windows.MessageBox]::Show($errorMsg,"Fatal Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) }
    catch { Write-Host $errorMsg -ForegroundColor Red }
}

"[$(Get-Date)] Script ended" | Add-Content $logFile
