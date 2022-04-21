function ShowVMLog ([string]$vmName, [PSCredential]$cred) {

    $parentRunspace = [runspacefactory]::CreateRunspace()
    $parentRunspace.ApartmentState = "STA"
    $parentRunspace.ThreadOptions = "ReuseThread"
    $parentRunspace.Open()

    $code = {
        Param
        (
            [string]$vmName,
            [pscredential]$credentials
        )

        Add-Type -AssemblyName PresentationFramework

        [xml]$gui = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    Height="500" Width="800" Topmost="False"
>
    <Grid>
        <Grid.RowDefinitions>
		    <RowDefinition Height="*" />
		    <RowDefinition Height="40" />
	    </Grid.RowDefinitions>
        <DataGrid 
            AutoGenerateColumns="False" 
            HorizontalAlignment="Stretch" 
            x:Name="eventsDataGrid" 
            VerticalAlignment="Stretch" 
            Grid.Row="0"
            HeadersVisibility="All" 
            IsReadOnly="True"
            ScrollViewer.CanContentScroll="True"
            EnableRowVirtualization="True"
            EnableColumnVirtualization="True"
            VirtualizingPanel.IsVirtualizingWhenGrouping="True"
            VirtualizingPanel.VirtualizationMode="Standard"
            VirtualizingPanel.IsVirtualizing="True"
        >
            <DataGrid.Columns>
                <DataGridTextColumn Header="TimeCreated"
                    Binding="{Binding TimeCreated}" 
                    SortDirection="Descending"
                />
                <DataGridTextColumn Header="Message"
                    Binding="{Binding Message}"
                    Width="*" 
                />
            </DataGrid.Columns>
        </DataGrid >
        <!--<Button x:Name="btn_Refresh" Content="Refresh" HorizontalAlignment="Right" VerticalAlignment="Center" Width="85" Grid.Row="1" Margin="0,5,5,5"/>-->
        <Label x:Name="lbl_WaitingForMachine" Content="warte auf Maschine..." Visibility="Visible" Grid.Row="1" Margin="0,5,5,5" HorizontalAlignment="Center" VerticalAlignment="Center"/>
        <Ellipse x:Name="ellipse_Status" Width="15" Height="15" Fill="Red" Grid.Row="1" HorizontalAlignment="Left" Margin="5,5,0,5"/> 
    </Grid>
</Window> 
"@

        function RefreshEvents {
    
            param([Hashtable]$syncHash, [string]$vmName, [PSCredential]$credentials)
    
            $syncHash.Host = $host

            $nestedRunspace = [RunspaceFactory]::CreateRunspace()
            $nestedRunspace.ApartmentState = "STA"
            $nestedRunspace.ThreadOptions = "ReuseThread"
            $nestedRunspace.Open()

            $nestedRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash) 
            $nestedRunspace.SessionStateProxy.SetVariable("vmName", $vmName)
            $nestedRunspace.SessionStateProxy.SetVariable("credentials", $credentials)
 
            $nestedCode = {

                function GetScrollViewer([System.Windows.UIElement]$parentElement) {
                    if ($null -eq $parentElement) {
                        return $null
                    }

                    $childrenCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($parentElement)
                    for ($i = 0; $i -lt $childrenCount; $i++) {
                        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($parentElement, $i)
                        if ($child -is [System.Windows.Controls.ScrollViewer]) {
                            return $child
                        }
                        $scrollerInChild = GetScrollViewer -parentElement $child
                        if ($null -ne $scrollerInChild) {
                            return $scrollerInChild
                        }
                    }
                    return $null
                }

                while ($true) {   

                    $reachable = $false
                    
                    try {
                        $events = Invoke-Command -VMName $vmName -Credential $credentials `
                            -ScriptBlock { Get-WinEvent -LogName microsoft-windows-dsc/analytic -Oldest | select TimeCreated, Message | sort TimeCreated -Descending } -ErrorAction Stop 

                        $syncHash.Window.Dispatcher.invoke([action] { 
                            $scrollViewer = GetScrollViewer -parentElement ([System.Windows.UIElement]$syncHash.eventsDataGrid)
                            if ($null -ne $scrollViewer) {
                                $offset = $scrollViewer.VerticalOffset
                            }
                            $selectedItem = $syncHash.eventsDataGrid.SelectedItem
                            if ($null -ne $selectedItem) {
                                $selectedItemId = $selectedItem.RecordId
                            }

                            $syncHash.dataGrid1.ItemsSource = $events
                            $syncHash.lbl_WaitingForMachine.Visibility = 'Hidden' 

                            if ($null -ne $selectedItemId) {
                                $itemToFocus = $syncHash.eventsDataGrid.ItemsSource.Where({$_.RecordId -eq $selectedItemId}) | select -First 1
                                $syncHash.eventsDataGrid.SelectedItem = $itemToFocus
                                $syncHash.eventsDataGrid.Focus()
                                #$syncHash.eventsDataGrid.ScrollIntoView($itemToFocus)
                                #$syncHash.eventsDataGrid.UpdateLayout()
                            }
                            if ($null -ne $scrollViewer -and $null -ne $offset) {
                                $scrollViewer.ScrollToVerticalOffset($offset)
                            }
                        })
                        $reachable = $true

                    }
                    catch [Exception] {
                        $syncHash.Window.Dispatcher.invoke([action] {                         
                            $syncHash.lbl_WaitingForMachine.Visibility = 'Visible' 
                            $syncHash.ellipse_Status.Fill = 'Red'
                        })
                        start-sleep -seconds 5
                    }

                    if ($reachable -eq $true) {
                        try {
                            $deploymentStatus = Invoke-Command -VMName $vmName -Credential $credentials `
                                -ScriptBlock { Get-DscConfigurationStatus | select -ExpandProperty Status } -ErrorAction Stop
                            if ($deploymentStatus -eq "Success" ) {
                                $syncHash.Window.Dispatcher.invoke([action] { 
                                        $syncHash.ellipse_Status.Fill = 'Green'
                                    })
                            }
                            else {
                                $syncHash.Window.Dispatcher.invoke([action] { 
                                    $syncHash.ellipse_Status.Fill = 'Red'
                                })
                            }
                        }
                        catch [Exception] {
                            $syncHash.Window.Dispatcher.invoke([action] { 
                                $syncHash.ellipse_Status.Fill = 'Red'
                            })
                        }
                    }
                }                    
            }

            $childPSInstance = [powershell]::Create().AddScript($nestedCode)
            $childPSInstance.Runspace = $nestedRunspace
            $childPSInstance.BeginInvoke() | out-null
        } 

        $reader = (New-Object System.Xml.XmlNodeReader $gui)
        $syncHash = [hashtable]::Synchronized(@{})
        $syncHash.Window = [Windows.Markup.XamlReader]::Load($reader)

        $syncHash.eventsDataGrid = $syncHash.Window.FindName("eventsDataGrid")
        $syncHash.lbl_WaitingForMachine = $syncHash.Window.FindName("lbl_WaitingForMachine")
        $syncHash.ellipse_Status = $syncHash.Window.FindName("ellipse_Status")
            
        RefreshEvents -syncHash $syncHash -vmName $vmName -credentials $credentials

        $syncHash.Window.Title = "Deploymentstatus $($vmName)"
        $syncHash.Window.ShowDialog()
        $syncHash.Window.Activate()
        $nestedRunspace.Close()
        $nestedRunspace.Dispose()
    }

    $parentPSInstance = [powershell]::Create().AddScript($Code)
    $parentPSInstance.AddArgument($vmName) | Out-Null
    $parentPSInstance.AddArgument($cred) | out-null
    $parentPSInstance.Runspace = $parentRunspace

    return $parentPSInstance.BeginInvoke()
}