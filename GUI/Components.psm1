# GUI/Components.psm1

Add-Type -AssemblyName PresentationFramework

# Standard-Button erstellen 
function New-StandardButton {
    param(
        [string]$Content,
        [string]$ToolTip = "",
        [scriptblock]$ClickHandler = {},
        [int]$MinWidth = 300,
        [int]$MinHeight = 80,
        [string]$Background = "Gray"
    )
    
    $button = New-Object System.Windows.Controls.Button
    $button.Content = $Content
    $button.MinWidth = $MinWidth
    $button.MinHeight = $MinHeight
    $button.Margin = [System.Windows.Thickness]::new(10)
    $button.Padding = [System.Windows.Thickness]::new(20, 15, 20, 15)
    $button.FontSize = 32
    $button.Background = [System.Windows.Media.Brushes]::$Background
    $button.Foreground = [System.Windows.Media.Brushes]::White
    
    if ($ToolTip) {
        $button.ToolTip = $ToolTip
    }
    
    if ($ClickHandler) {
        $button.Add_Click($ClickHandler)
    }
    
    return $button
}

# Back-Button erstellen
function New-BackButton {
    param(
        [scriptblock]$ClickHandler = {
            $script:submenuPanel.Visibility = 'Collapsed'
            $script:mainPanel.Visibility = 'Visible'
        }
    )
    
    $button = New-Object System.Windows.Controls.Button
    $button.Content = "Back"
    $button.MinWidth = 300
    $button.MinHeight = 80
    $button.Margin = [System.Windows.Thickness]::new(10)
    $button.Padding = [System.Windows.Thickness]::new(20, 15, 20, 15)
    $button.FontSize = 32
    $button.Background = [System.Windows.Media.Brushes]::DarkGray
    $button.Foreground = [System.Windows.Media.Brushes]::White
    $button.Add_Click($ClickHandler)
    
    return $button
}

# Progress Window erstellen
function Show-ProgressWindow {
    param(
        [string]$Title = "Progress",
        [string]$Message = "Please wait..."
    )
    
    $progressWindow = [System.Windows.Window]@{
        Title = $Title
        Width = 500
        Height = 200
        WindowStartupLocation = "CenterScreen"
        Background = "#FF1E1E1E"
    }
    
    $progressPanel = New-Object System.Windows.Controls.StackPanel
    $progressPanel.Margin = [System.Windows.Thickness]::new(20)
    
    $progressText = New-Object System.Windows.Controls.TextBlock
    $progressText.Foreground = "White"
    $progressText.FontSize = 16
    $progressText.TextWrapping = "Wrap"
    $progressText.TextAlignment = "Center"
    $progressText.Text = $Message
    $progressPanel.Children.Add($progressText)
    
    $progressWindow.Content = $progressPanel
    $progressWindow.Show()
    
    return @{
        Window = $progressWindow
        TextBlock = $progressText
    }
}

# Disk RadioButton mit Template erstellen
function New-DiskRadioButton {
    param(
        [string]$Content,
        [object]$Tag,
        [string]$GroupName = "DiskSelection",
        [scriptblock]$CheckedHandler = {}
    )
    
    $radioButton = New-Object System.Windows.Controls.RadioButton
    $radioButton.Margin = [System.Windows.Thickness]::new(10)
    $radioButton.Padding = [System.Windows.Thickness]::new(10)
    $radioButton.FontSize = 16
    $radioButton.Foreground = "White"
    $radioButton.GroupName = $GroupName
    $radioButton.VerticalContentAlignment = "Center"
    $radioButton.MinHeight = 30
    $radioButton.Content = $Content
    $radioButton.Tag = $Tag
    
    # Template wie im Original
    $template = "<ControlTemplate xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml' TargetType='RadioButton'>
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width='24'/>
                <ColumnDefinition Width='*'/>
            </Grid.ColumnDefinitions>
            <Ellipse x:Name='RadioOuter' Height='20' Width='20' Stroke='{TemplateBinding Foreground}' Fill='Transparent' StrokeThickness='2'/>
            <Ellipse x:Name='RadioInner' Height='10' Width='10' Margin='5' Fill='{TemplateBinding Foreground}' Opacity='0'/>
            <ContentPresenter Grid.Column='1' Margin='10,0,0,0' VerticalAlignment='Center' HorizontalAlignment='Left'/>
        </Grid>
        <ControlTemplate.Triggers>
            <Trigger Property='IsChecked' Value='True'>
                <Setter TargetName='RadioInner' Property='Opacity' Value='1'/>
            </Trigger>
        </ControlTemplate.Triggers>
    </ControlTemplate>"
    
    $radioButton.Template = [System.Windows.Markup.XamlReader]::Parse($template)
    
    if ($CheckedHandler) {
        $radioButton.Add_Checked($CheckedHandler)
    }
    
    return $radioButton
}

# Disk Selection Panel erstellen
function New-DiskSelectionPanel {
    param(
        [switch]$ExcludeUSB = $true,
        [switch]$UseSnapshotNumbering = $false,
        [string]$GroupName = "DiskSelection"
    )
    
    $scrollViewer = New-Object System.Windows.Controls.ScrollViewer
    $scrollViewer.VerticalScrollBarVisibility = "Auto"
    $scrollViewer.HorizontalScrollBarVisibility = "Disabled"
    $scrollViewer.MaxHeight = 400
    $scrollViewer.Margin = [System.Windows.Thickness]::new(10)
    
    $stackPanel = New-Object System.Windows.Controls.StackPanel
    
    try {
        # Get physical disks
        $physicalDisks = if ($ExcludeUSB) {
            Get-WmiObject Win32_DiskDrive | Where-Object { $_.InterfaceType -ne "USB" }
        } else {
            Get-WmiObject Win32_DiskDrive
        }
        
        foreach ($disk in $physicalDisks) {
            $border = New-Object System.Windows.Controls.Border
            $border.BorderBrush = "#FF6E6E6E"
            $border.BorderThickness = [System.Windows.Thickness]::new(2)
            $border.CornerRadius = [System.Windows.CornerRadius]::new(5)
            $border.Margin = [System.Windows.Thickness]::new(10)
            $border.Background = "#FF4A4A4A"
            
            $sizeGB = [math]::Round($disk.Size / 1GB, 2)
            $diskNum = [int]($disk.DeviceID -replace '\\\\\.\\PHYSICALDRIVE', '')
            
            # DriveSnapshot verwendet HD1, HD2 etc.
            if ($UseSnapshotNumbering) {
                $displayNum = $diskNum + 1
                $content = "HD$($displayNum): $($disk.Model) ($sizeGB GB)"
                $tag = $displayNum
            } else {
                $content = "Disk $($diskNum): $($disk.Model) ($sizeGB GB)"
                $tag = $diskNum
            }
            
            $diskButton = New-DiskRadioButton -Content $content -Tag $tag -GroupName $GroupName
            
            $border.Child = $diskButton
            $stackPanel.Children.Add($border)
        }
    }
    catch {
        Write-Error "Failed to enumerate disks: $_"
    }
    
    $scrollViewer.Content = $stackPanel
    return $scrollViewer
}

# Label erstellen
function New-Label {
    param(
        [string]$Content,
        [string]$Foreground = "White",
        [int]$FontSize = 24,
        [string]$HorizontalAlignment = "Center"
    )
    
    $label = New-Object System.Windows.Controls.Label
    $label.Content = $Content
    $label.Foreground = $Foreground
    $label.FontSize = $FontSize
    $label.HorizontalAlignment = $HorizontalAlignment
    $label.Margin = [System.Windows.Thickness]::new(10)
    
    return $label
}

# TextBox erstellen
function New-TextBox {
    param(
        [int]$MinWidth = 400,
        [int]$FontSize = 24
    )
    
    $textBox = New-Object System.Windows.Controls.TextBox
    $textBox.FontSize = $FontSize
    $textBox.Padding = [System.Windows.Thickness]::new(10)
    $textBox.Margin = [System.Windows.Thickness]::new(50, 10, 50, 20)
    $textBox.HorizontalAlignment = "Center"
    $textBox.MinWidth = $MinWidth
    $textBox.Background = "#FF4A4A4A"
    $textBox.Foreground = "White"
    $textBox.BorderBrush = "#FF6E6E6E"
    $textBox.BorderThickness = 2
    
    return $textBox
}

# Confirmation Button Handler
function Add-ConfirmationBehavior {
    param(
        [System.Windows.Controls.Button]$Button,
        [string]$WarningText = "Confirm! Data will be wiped!",
        [scriptblock]$OnConfirm
    )
    
    $originalContent = $Button.Content
    $originalBackground = $Button.Background
    $script:confirmationRequired = $true
    
    $Button.Add_Click({
        if ($script:confirmationRequired) {
            $this.Content = $WarningText
            $this.Background = [System.Windows.Media.Brushes]::Red
            $script:confirmationRequired = $false
        }
        else {
            & $OnConfirm
            $this.Content = $originalContent
            $this.Background = $originalBackground
            $script:confirmationRequired = $true
        }
    }.GetNewClosure())
}

Export-ModuleMember -Function @(
    'New-StandardButton',
    'New-BackButton',
    'Show-ProgressWindow',
    'New-DiskRadioButton',
    'New-DiskSelectionPanel',
    'New-Label',
    'New-TextBox',
    'Add-ConfirmationBehavior'
)