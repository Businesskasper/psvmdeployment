Import-Module xDscHelper

try {
    Write-InformationLog -source UpdateDnsForwarder -entryType Information -message "Starting DNS service"
    Set-Service -Name DNS -Status Running -ErrorAction Stop
}
catch {
    Write-InformationLog -source UpdateDnsForwarder -entryType Error -message"Could not start Service!"
    Break
}

try {
    Write-InformationLog -source UpdateDnsForwarder -entryType Information -message "Importing DnsServer Module"
    Import-Module DnsServer
}
catch {
    Write-InformationLog -source UpdateDnsForwarder -entryType Warning -message "Could not import - DNS probably isn't installed yet"
    Break
}

$dhcp = Get-WmiObject Win32_NetworkAdapterConfiguration | ? { $_.DHCPEnabled -eq $true -and $_.DHCPServer -ne $null } | select -ExpandProperty DHCPServer

if ($null -ne $dhcp) {
    Write-InformationLog -source UpdateDnsForwarder -entryType Information -message "Found $($dhcp) as external DHCP and DNS address from HV NAT switch - updating Forwarders"
    
    try {
        Get-DnsServerForwarder | Remove-DnsServerForwarder -Force | Out-Null
        Add-DnsServerForwarder -IPAddress $dhcp | Out-Null
    }
    catch {
        Write-InformationLog -source UpdateDnsForwarder -entryType Error -message "Failed :("
    }
}
