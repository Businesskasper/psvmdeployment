function GetNicTask([hashtable[]]$nics) {

    $nicTask += @"
Import-Module xDscHelper

"@
    foreach ($nic in ($nics | ? { $_.IPAddress })) {

        $nicTask += @"
#Updating $($nic.SwitchName)

`$adapter = Get-NetAdapterAdvancedProperty -DisplayName "Hyper-V Network Adapter Name" | ? {`$_.DisplayValue -eq "$($nic.SwitchName)"} | select -ExpandProperty Name
Write-InformationLog -source UpdateNicIP_$($nic.SwitchName) -entryType Information -message "Found adapter `$(`$adapter)"

if (`$$($nic.DHCP)) {
    Write-InformationLog -source UpdateNicIP_$($nic.SwitchName) -entryType Information -message "Enabling DHCP on `$(`$adapter)"    
    Set-NetIPInterface -InterfaceAlias `$adapter -Dhcp Enabled

    Write-InformationLog -source UpdateNicIP_$($nic.SwitchName) -entryType Information -message "Resetting DNS on `$(`$adapter)"    
    Set-DnsClientServerAddress -InterfaceAlias `$adapter -ResetServerAddresses 
}
elseif ((Get-NetIPAddress -InterfaceAlias `$adapter | ? {`$_.AddressFamily -ne "IPv6"}).IPAddress -ne "$($nic.IPAddress)") {
    Write-InformationLog -source UpdateNicIP_$($nic.SwitchName) -entryType Information -message "Removing addresses on `$(`$adapter)"    
    Get-NetIPAddress -InterfaceAlias `$adapter | ? {`$_.AddressFamily -ne "IPv6"} | Remove-NetIPAddress -Confirm:`$false

    Write-InformationLog -source UpdateNicIP_$($nic.SwitchName) -entryType Information -message "Assign $($nic.IPAddress)/$($nic.SubnetCidr) to `$(`$adapter)"   
    New-NetIPAddress –InterfaceAlias `$adapter –IPAddress $($nic.IPAddress) –PrefixLength $($nic.SubnetCidr) -AddressFamily IPv4

    Write-InformationLog -source UpdateNicIP_$($nic.SwitchName) -entryType Information -message "Setting DNS on `$(`$adapter) to $($nic.DNSAddress)"    
    Set-DnsClientServerAddress -InterfaceAlias `$adapter -ResetServerAddresses
    Set-DnsClientServerAddress -InterfaceAlias `$adapter -ServerAddresses @("$($nic.DNSAddress)") 
}
"@
    }

    return $nicTask
}