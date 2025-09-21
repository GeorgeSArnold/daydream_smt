# main.ps1 Daydream System Management Tool - Windows PE Monolithic Version

# ----------------------------
# Configuration and Resources
# ----------------------------

# Load the WPF PresentationFramework assembly
Add-Type -AssemblyName PresentationFramework

# Error handling function
function Write-ErrorLog {
    param([string]$message)
    Write-Host $message -ForegroundColor Red
    [System.Windows.MessageBox]::Show($message, "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
}

# Automatische Pfad-Erkennung (Windows vs PE)
if (Test-Path "X:\DaydreamSMT") {
    # Windows PE Umgebung
    $scriptDirectory = "X:\DaydreamSMT"
} else {
    # Normale Windows Umgebung - aktuelles Verzeichnis verwenden
    $scriptDirectory = Split-Path $MyInvocation.MyCommand.Path
}
$logoFile        = Join-Path $scriptDirectory "logo.png"
$toolsDir        = Join-Path $scriptDirectory "Tools"
$snapshotPath    = Join-Path $toolsDir "snapshot64.exe"

# Check if snapshot64.exe exists
if (-not (Test-Path $snapshotPath)) {
    Write-ErrorLog "The snapshot64.exe was not found in directory: $toolsDir"
    exit
}

# Define the folder where captures will be stored.
$captureFolder = "$scriptDirectory\IMAGES"
try {
    if (-not (Test-Path $captureFolder)) {
        New-Item -ItemType Directory -Path $captureFolder -ErrorAction Stop | Out-Null
    }
} catch {
    Write-ErrorLog "Failed to create capture folder: $_"
    exit
}

# Ensure that essential files exist
if (-not (Test-Path $logoFile)) {
    Write-ErrorLog "The logo file 'logo.png' was not found in directory: $scriptDirectory"
    exit
}

# ----------------------------
# System Information Retrieval (PE-Safe)
# ----------------------------

try {
    # Try to get system info, but handle PE limitations gracefully
    $biosInfo = Get-WmiObject Win32_BIOS -ErrorAction Stop | 
                Select-Object -Property Manufacturer, SMBIOSBIOSVersion, ReleaseDate
    $pcInfo   = Get-WmiObject Win32_ComputerSystem -ErrorAction Stop | 
                Select-Object -Property Manufacturer, Model, TotalPhysicalMemory
    $serialNumber = (Get-WmiObject -Query "SELECT SerialNumber FROM Win32_BIOS" -ErrorAction Stop).SerialNumber
    
    # Get OEM Strings and handle empty or null values
    try {
        $oemStringsObj = Get-WmiObject -Query "SELECT OEMStringArray FROM Win32_ComputerSystem" -ErrorAction Stop
        if ($oemStringsObj -and $oemStringsObj.OEMStringArray) {
            $oemStringArray = $oemStringsObj.OEMStringArray | Where-Object { $_ } | ForEach-Object { $_.ToString().Trim() }
        } else {
            $oemStringArray = @("No OEM Strings available")
        }
    } catch {
        $oemStringArray = @("No OEM Strings available")
    }
    
    # Get Config Options and handle empty or null values
    try {
        $configOptionsObj = Get-WmiObject -Query "SELECT ConfigOptions FROM Win32_BaseBoard" -ErrorAction Stop
        if ($configOptionsObj -and $configOptionsObj.ConfigOptions) {
            $configOptions = $configOptionsObj.ConfigOptions | Where-Object { $_ } | ForEach-Object { $_.ToString().Trim() }
        } else {
            $configOptions = @("No Config Options available")
        }
    } catch {
        $configOptions = @("No Config Options available")
    }

    # --- OS Version ---
    try {
        $os = Get-CimInstance Win32_OperatingSystem | Select-Object -First 1
        $osText = "OS: $($os.Caption) $($os.Version)"
    } catch {
        $osText = "OS: Windows PE"
    }

    # --- CPU Name und MHz ---
    try {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $cpuText = "CPU: $($cpu.Name.Trim()) @ $($cpu.MaxClockSpeed) MHz"
    } catch {
        $cpuText = "CPU: N/A"
    }

    # Alle aktiven Netzwerkadapter mit MAC sammeln
    try {
        $macs = @(Get-CimInstance Win32_NetworkAdapterConfiguration |
                   Where-Object { $_.MACAddress -and $_.IPEnabled } |
                   ForEach-Object { $_.MACAddress })

        # Ausgabeformat
        if ($macs.Count -gt 1) {
            $macText = "MACs:`n" + ($macs -join "`n")
        } elseif ($macs.Count -eq 1) {
            $macText = "MAC: $($macs[0])"
        } else {
            $macText = "MAC: N/A"
        }
    } catch {
        $macText = "MAC: N/A"
    }

} catch {
    # PE Fallback - basic info only
    Write-Host "Using PE fallback for system information" -ForegroundColor Yellow
    $biosInfo = @{
        Manufacturer = "Windows PE"
        SMBIOSBIOSVersion = "N/A"
        ReleaseDate = "N/A"
    }
    $pcInfo = @{
        Manufacturer = "Windows PE"
        Model = "Live Environment"
        TotalPhysicalMemory = 2GB  # Default assumption
    }
    $serialNumber = "N/A"
    $oemStringArray = @("Windows PE Environment")
    $configOptions = @("Windows PE Environment")
    $osText = "OS: Windows PE"
    $cpuText = "CPU: N/A"
    $macText = "MAC: N/A"
}

# Format OEM Strings and Config Options for display
$oemStringsText = if ($oemStringArray.Count -gt 0) {
    $oemStringArray -join "`n"
} else {
    "No OEM Strings available"
}

$configOptionsText = if ($configOptions.Count -gt 0) {
    $configOptions -join "`n"
} else {
    "No Config Options available"
}

$extraInfoText = "$osText`n$cpuText`n$macText"

# ----------------------------
# XAML GUI Layout
# ----------------------------

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None"
        ResizeMode="NoResize"
        Topmost="False"
        WindowState="Maximized"
        Background="#FF1E1E1E">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#7378ffeb"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="32"/>
            <Setter Property="Margin" Value="10"/>
            <Setter Property="Padding" Value="20,15"/>
            <Setter Property="MinWidth" Value="300"/>
            <Setter Property="MinHeight" Value="80"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="#FF6E6E6E"
                                BorderThickness="2"
                                CornerRadius="5">
                            <ContentPresenter HorizontalAlignment="Center"
                                            VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#FF6E6E6E"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#FF858585"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ScrollViewer">
            <Setter Property="VerticalScrollBarVisibility" Value="Auto"/>
            <Setter Property="HorizontalScrollBarVisibility" Value="Disabled"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollViewer">
                        <Grid>
                            <ScrollContentPresenter />
                            <ScrollBar Name="PART_VerticalScrollBar"
                                      HorizontalAlignment="Right"
                                      Maximum="{TemplateBinding ScrollableHeight}"
                                      ViewportSize="{TemplateBinding ViewportHeight}"
                                      Visibility="{TemplateBinding ComputedVerticalScrollBarVisibility}"
                                      Value="{TemplateBinding VerticalOffset}"
                                      Opacity="0.3" />
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="1*"/>
            <ColumnDefinition Width="2*"/>
        </Grid.ColumnDefinitions>
        
        <!-- Left Panel: Logo and System Info -->
        <StackPanel Grid.Column="0" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10">
            <!-- Professionelles Logo -->
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Left" Margin="5">
                <TextBlock Text="&#xE753;" FontFamily="Segoe MDL2 Assets" FontSize="50" 
                           Foreground="#57198aeb" VerticalAlignment="Center" Margin="0,0,15,0"/>
                <StackPanel VerticalAlignment="Center">
                    <TextBlock Text="daydream" FontFamily="Segoe UI Light" FontSize="36" FontWeight="Light"
                               Foreground="#FFF0F8FF" VerticalAlignment="Center"/>
                    <TextBlock Text="System-Management-Tool" FontSize="10" 
                               Foreground="#FFAAAAAA" Margin="0,2,0,0"/>
                </StackPanel>
            </StackPanel>
            
            <!-- Version Info -->
            <TextBlock Text="v0.0.1 gSa 09-2025" FontSize="9" Foreground="#FF777777" 
                       Margin="10,5,0,20" TextAlignment="Left"/>

            <!-- Your Logo: -->
            <Image Name="Logo" Width="200" Height="200" HorizontalAlignment="Left" Margin="5"/>

            <!-- System Information Section -->
            <TextBlock Text="System Information" FontSize="24" Foreground="White" 
                       Margin="10,20,10,10" TextAlignment="Left"/>
            <TextBlock Name="BiosInfo" FontSize="16" Foreground="White" Margin="5" TextAlignment="Left"/>
            <TextBlock Name="PCInfo" FontSize="16" Foreground="White" Margin="5" TextAlignment="Left"/>
            <TextBlock Name="ExtraInfo" FontSize="16" Foreground="White" Margin="5" TextAlignment="Left"/>
        </StackPanel>

        <!-- Right Panel: Buttons -->
        <StackPanel Grid.Column="1" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="20">
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <Grid>
                    <!-- Two overlapping panels -->
                    <StackPanel x:Name="MainButtonPanel" Visibility="Visible"/>
                    <StackPanel x:Name="SubmenuPanel" Visibility="Collapsed"/>
                </Grid>
            </ScrollViewer>
            <StackPanel x:Name="ExitButtonsPanel" Orientation="Horizontal" HorizontalAlignment="Center" Margin="10">
                <Button x:Name="ShutdownButton" MinWidth="150" MinHeight="80" Margin="10" Background="#5E3B4F7E" Foreground="White" ToolTip="Shutdown system">
                    <StackPanel Orientation="Vertical" HorizontalAlignment="Center">
                        <TextBlock Text="&#xE7E8;" FontFamily="Segoe MDL2 Assets" FontSize="32" HorizontalAlignment="Center"/>
                        <TextBlock Text="Shutdown" FontSize="18" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Button>
                <Button x:Name="TerminalButton" MinWidth="150" MinHeight="80" Margin="10" Background="#0d00004c" Foreground="White" ToolTip="Open Terminal as Administrator">
                    <StackPanel Orientation="Vertical" HorizontalAlignment="Center">
                        <TextBlock Text="&#xE756;" FontFamily="Segoe MDL2 Assets" FontSize="32" HorizontalAlignment="Center"/>
                        <TextBlock Text="Terminal" FontSize="18" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Button>
                <Button x:Name="RestartButton" MinWidth="150" MinHeight="80" Margin="10" Background="#5E3B4F7E" Foreground="White" ToolTip="Restart system">
                    <StackPanel Orientation="Vertical" HorizontalAlignment="Center">
                        <TextBlock Text="&#xE777;" FontFamily="Segoe MDL2 Assets" FontSize="32" HorizontalAlignment="Center"/>
                        <TextBlock Text="Restart" FontSize="18" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Button>
            </StackPanel>
        </StackPanel>
    </Grid>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader $xaml))
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# ----------------------------
# Set System Info in GUI with PE-Safe fallback
# ----------------------------

$biosText = "BIOS Manufacturer: $($biosInfo.Manufacturer)`nVersion: $($biosInfo.SMBIOSBIOSVersion)`nRelease: $($biosInfo.ReleaseDate)"
$pcText   = "Manufacturer: $($pcInfo.Manufacturer)`nModel: $($pcInfo.Model)`nRAM: $([math]::Round($pcInfo.TotalPhysicalMemory / 1GB)) GB"

$window.FindName("BiosInfo").Text = $biosText
$window.FindName("PCInfo").Text   = $pcText
$window.FindName("ExtraInfo").Text = $extraInfoText

# Load the logo image
$logoImage = $window.FindName("Logo")
if ($logoImage -and (Test-Path $logoFile)) {
    $logoImage.Source = New-Object System.Windows.Media.Imaging.BitmapImage
    $logoImage.Source.BeginInit()
    $logoImage.Source.UriSource = [System.Uri]::new($logoFile)
    $logoImage.Source.EndInit()
}

# ----------------------------
# Build Main Panel Buttons
# ----------------------------

$mainPanel    = $window.FindName("MainButtonPanel")
$submenuPanel = $window.FindName("SubmenuPanel")

# SNAPSHOT Button - Direct EXE launch
$snapButton = New-Object System.Windows.Controls.Button
$snapButton.Content = "SnapShot v1.50"
$snapButton.ToolTip = "Launch DriveSnapshot for disk imaging"
$snapButton.Add_Click({
    try {
        if (Test-Path $snapshotPath) { 
            Start-Process $snapshotPath -Verb RunAs 
        } else { 
            [System.Windows.MessageBox]::Show("Snapshot64.exe not found: $snapshotPath","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) 
        }
    } catch { 
        [System.Windows.MessageBox]::Show("Error starting snapshot: $_","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) 
    }
})
$mainPanel.Children.Add($snapButton)

# GUID Button
$guidButton = New-Object System.Windows.Controls.Button
$guidButton.Content = "set GUID"
$guidButton.ToolTip = "Set BIOS ID/Serial Number"
$guidButton.Add_Click({
    try {
        $guidSetPath = Join-Path $toolsDir "GUIDSET.EXE"
        
        if (-not (Test-Path $guidSetPath)) {
            throw "GUIDSET.EXE not found in Tools directory"
        }
        
        $process = Start-Process -FilePath $guidSetPath -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            [System.Windows.MessageBox]::Show("BIOS ID set successfully!", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            throw "GUIDSET.EXE failed with exit code: $($process.ExitCode)"
        }
    }
    catch {
        [System.Windows.MessageBox]::Show("Failed to set BIOS ID: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
})
$mainPanel.Children.Add($guidButton)

# DiskPart Button (PE Disk Management)
$diskpartButton = New-Object System.Windows.Controls.Button
$diskpartButton.Content = "DiskPart"
$diskpartButton.ToolTip = "Open DiskPart for disk partitioning"
$diskpartButton.Add_Click({
    try { 
        Start-Process cmd.exe -ArgumentList "/k diskpart"
    }
    catch { 
        [System.Windows.MessageBox]::Show("Error opening DiskPart: $_","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) 
    }
})
$mainPanel.Children.Add($diskpartButton)

# ----------------------------
# Exit Buttons Setup
# ----------------------------

$shutdownButton = $window.FindName("ShutdownButton")
$restartButton = $window.FindName("RestartButton")
$terminalButton = $window.FindName("TerminalButton")

$shutdownButton.Add_Click({
    $window.Close()
    Stop-Computer -Force
})

$restartButton.Add_Click({
    $window.Close()
    Restart-Computer -Force
})

$terminalButton.Add_Click({
    try {
        # Windows Terminal als Administrator öffnen
        Start-Process -FilePath "wt.exe" -Verb RunAs
    }
    catch {
        try {
            # Fallback: PowerShell als Administrator öffnen
            Start-Process -FilePath "powershell.exe" -Verb RunAs
        }
        catch {
            # Letzter Fallback: CMD als Administrator öffnen
            Start-Process -FilePath "cmd.exe" -Verb RunAs
        }
    }
})

# ----------------------------
# Show Window
# ----------------------------

$window.ShowDialog()