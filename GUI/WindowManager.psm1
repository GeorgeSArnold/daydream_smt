# GUI/WindowManager.psm1

Add-Type -AssemblyName PresentationFramework

# Hauptfenster
function New-MainWindow {
    param(
        [string]$LogoPath = ""
    )

    # XAML
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

    # Window laden
    $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader $xaml))
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    # Logo laden wenn Pfad angegeben (optional, da wir jetzt ein Icon-Logo haben)
    if ($LogoPath -and (Test-Path $LogoPath)) {
        $logoImage = $window.FindName("Logo")
        if ($logoImage) {
            $logoImage.Source = New-Object System.Windows.Media.Imaging.BitmapImage
            $logoImage.Source.BeginInit()
            $logoImage.Source.UriSource = [System.Uri]::new($LogoPath)
            $logoImage.Source.EndInit()
        }
    }

    return $window
}

# System Info aktualisieren
function Update-SystemInfo {
    param(
        [System.Windows.Window]$Window
    )

    try {
        $biosInfo = Get-WmiObject Win32_BIOS -ErrorAction Stop |
                    Select-Object -Property Manufacturer, SMBIOSBIOSVersion, ReleaseDate
        $pcInfo   = Get-WmiObject Win32_ComputerSystem -ErrorAction Stop |
                    Select-Object -Property Manufacturer, Model, TotalPhysicalMemory
        $serialNumber = (Get-WmiObject -Query "SELECT SerialNumber FROM Win32_BIOS" -ErrorAction Stop).SerialNumber

        # Get OEM Strings
        $oemStringsObj = Get-WmiObject -Query "SELECT OEMStringArray FROM Win32_ComputerSystem" -ErrorAction Stop
        if ($oemStringsObj -and $oemStringsObj.OEMStringArray) {
            $oemStringArray = $oemStringsObj.OEMStringArray | Where-Object { $_ } | ForEach-Object { $_.ToString().Trim() }
        } else {
            $oemStringArray = @("No OEM Strings available")
        }

        # Get Config Options
        $configOptionsObj = Get-WmiObject -Query "SELECT ConfigOptions FROM Win32_BaseBoard" -ErrorAction Stop
        if ($configOptionsObj -and $configOptionsObj.ConfigOptions) {
            $configOptions = $configOptionsObj.ConfigOptions | Where-Object { $_ } | ForEach-Object { $_.ToString().Trim() }
        } else {
            $configOptions = @("No Config Options available")
        }

        # Format für Display
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

        # --- BIOS / PC ---
        $biosText = "BIOS Manufacturer: $($biosInfo.Manufacturer)`nVersion: $($biosInfo.SMBIOSBIOSVersion)`nRelease: $($biosInfo.ReleaseDate)"
        $pcText   = "Manufacturer: $($pcInfo.Manufacturer)`nModel: $($pcInfo.Model)`nRAM: $([math]::Round($pcInfo.TotalPhysicalMemory / 1GB)) GB"

        # --- OS Version ---
        $os = Get-CimInstance Win32_OperatingSystem | Select-Object -First 1
        $osText = "OS: $($os.Caption) $($os.Version)"

        # --- CPU Name und MHz ---
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $cpuText = "CPU: $($cpu.Name.Trim()) @ $($cpu.MaxClockSpeed) MHz"

        # Alle aktiven Netzwerkadapter mit MAC sammeln
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

        # --- Extra Info zusammensetzen ---
        $extraInfoText = "$osText`n$cpuText`n$macText"

        # --- Update GUI ---
        $Window.FindName("BiosInfo").Text = $biosText
        $Window.FindName("PCInfo").Text   = $pcText
        $Window.FindName("ExtraInfo").Text = $extraInfoText

        return $true
    }
    catch {
        Write-Error "Failed to retrieve system information: $_"
        return $false
    }
}

# Exit Buttons Setup
function Setup-ExitButtons {
    param(
        [System.Windows.Window]$Window
    )

    $shutdownButton = $Window.FindName("ShutdownButton")
    $restartButton = $Window.FindName("RestartButton")
    $terminalButton = $Window.FindName("TerminalButton")

    $shutdownButton.Add_Click({
        $Window.Close()
        Stop-Computer -Force
    })

    $restartButton.Add_Click({
        $Window.Close()
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
}

Export-ModuleMember -Function @(
    'New-MainWindow',
    'Update-SystemInfo',
    'Setup-ExitButtons'
)