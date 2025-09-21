# GUI/PanelBuilder.psm1
# Panel-Inhalt Builder

# Import Components Module
$componentsPath = Join-Path $PSScriptRoot "Components.psm1"
if (Test-Path $componentsPath) {
    Import-Module $componentsPath -Force
}

# Build Capture Panel
function Build-CapturePanel {
    param(
        [System.Windows.Controls.Panel]$SubmenuPanel,
        [System.Windows.Controls.Panel]$MainPanel,
        [string]$SnapshotPath,
        [string]$CaptureFolder
    )
    
    $SubmenuPanel.Children.Clear()
    
    # Back button
    $backButton = New-BackButton
    $SubmenuPanel.Children.Add($backButton)
    
    # Name input section
    $nameLabel = New-Label -Content "Enter Backup Name:"
    $SubmenuPanel.Children.Add($nameLabel)
    
    $nameBox = New-TextBox
    $SubmenuPanel.Children.Add($nameBox)
    
    # Disk selection label
    $diskLabel = New-Label -Content "Select Disks to Backup:"
    $SubmenuPanel.Children.Add($diskLabel)
    
    # Disk selection panel
    $diskScrollViewer = New-DiskSelectionPanel -UseSnapshotNumbering -GroupName "BackupDiskSelection"
    $SubmenuPanel.Children.Add($diskScrollViewer)
    
    # Start Backup button
    $startButton = New-StandardButton -Content "Start Backup" -Background "Green" -MinHeight 60
    $startButton.FontSize = 24
    
    # Store references for click handler
    $script:backupNameBox = $nameBox
    $script:selectedDisk = $null
    
    # Add selection handler to disk buttons
    foreach ($border in $diskScrollViewer.Content.Children) {
        $radioButton = $border.Child
        $radioButton.Add_Checked({
            param($sender)
            $script:selectedDisk = $sender.Tag
        })
    }
    
    $startButton.Add_Click({
        $backupName = $script:backupNameBox.Text.Trim()
        
        if ([string]::IsNullOrWhiteSpace($backupName)) {
            [System.Windows.MessageBox]::Show("Please enter a backup name.", "Error", 
                [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        
        if ($null -eq $script:selectedDisk) {
            [System.Windows.MessageBox]::Show("Please select a disk to backup.", "Error", 
                [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        
        # Create backup folder
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
        $backupPath = Join-Path $CaptureFolder $backupName
        
        if (Test-Path $backupPath) {
            [System.Windows.MessageBox]::Show("A backup with this name already exists.", "Error",
                [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        
        $progressWindow = $null
        try {
            New-Item -ItemType Directory -Path $backupPath -ErrorAction Stop | Out-Null
            
            # Build snapshot command
            $outputFile = Join-Path $backupPath "$($backupName)-`$DISK-$timestamp.sna"
            $snapshotArgs = "HD$($script:selectedDisk):* `"$outputFile`" -Gx"
            
            # Show progress
            $progress = Show-ProgressWindow -Title "Backup Progress" `
                -Message "Starting backup of HD$($script:selectedDisk)...`nThis may take several minutes."
            
            # Execute snapshot
            $process = Start-Process -FilePath $SnapshotPath -ArgumentList $snapshotArgs -Wait -PassThru
            
            if ($process.ExitCode -ne 0) {
                throw "Backup failed with exit code: $($process.ExitCode)"
            }
            
            $progress.Window.Close()
            [System.Windows.MessageBox]::Show("Backup completed successfully!", "Success",
                [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            
            # Return to main panel
            $SubmenuPanel.Visibility = 'Collapsed'
            $MainPanel.Visibility = 'Visible'
            
        } catch {
            if ($progress) { $progress.Window.Close() }
            
            if (Test-Path $backupPath) {
                Remove-Item -Path $backupPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            [System.Windows.MessageBox]::Show($_.Exception.Message, "Error",
                [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })
    
    $SubmenuPanel.Children.Add($startButton)
    
    $MainPanel.Visibility = 'Collapsed'
    $SubmenuPanel.Visibility = 'Visible'
}

# Build GUID Panel (direkter Aufruf)
function Build-GUIDPanel {
    param(
        [string]$GuidSetPath,
        [System.Windows.Window]$Window
    )
    
    if (-not (Test-Path $GuidSetPath)) {
        [System.Windows.MessageBox]::Show("GUIDSET.EXE not found", "Error",
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }
    
    $progress = Show-ProgressWindow -Title "Setting BIOS ID" -Message "Setting BIOS ID... Please wait."
    
    try {
        $process = Start-Process -FilePath $GuidSetPath -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Start-Sleep -Seconds 2
            
            $progress.TextBlock.Text = "BIOS ID set successfully. Refreshing system information..."
            
            if (Update-SystemInfo -Window $Window) {
                $progress.Window.Close()
                [System.Windows.MessageBox]::Show("BIOS ID set successfully!", "Success",
                    [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            } else {
                $progress.Window.Close()
                [System.Windows.MessageBox]::Show("BIOS ID set but failed to refresh info.", "Warning",
                    [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            }
        } else {
            throw "GUIDSET.EXE failed with exit code: $($process.ExitCode)"
        }
    }
    catch {
        if ($progress) { $progress.Window.Close() }
        [System.Windows.MessageBox]::Show("Failed to set BIOS ID: $_", "Error",
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
}

# Build Flash Panel
function Build-FlashPanel {
    param(
        [System.Windows.Controls.Panel]$SubmenuPanel,
        [System.Windows.Controls.Panel]$MainPanel,
        [string]$BiosDir,
        [System.Windows.Window]$Window
    )
    
    $SubmenuPanel.Children.Clear()
    
    # Back button
    $backButton = New-BackButton
    $SubmenuPanel.Children.Add($backButton)
    
    # Instructions
    $label = New-Label -Content "Select BIOS ROM to flash:"
    $SubmenuPanel.Children.Add($label)
    
    if (-not (Test-Path $BiosDir)) {
        [System.Windows.MessageBox]::Show("BIOS directory not found", "Error",
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        $Submenu
    }

}