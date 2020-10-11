if ($psISE) {

    $global:root = $psISE.CurrentFile | select -ExpandProperty FullPath | Split-Path -Parent
}
else {

    $global:root = $MyInvocation.MyCommand.Definition | Split-Path -Parent 
}


. $global:root\ps\classes.ps1
. $global:root\ps\functions.ps1
. $global:root\ps\roles.ps1
$configData = . $global:root\nodeDefinition.ps1

Write-Host "Erstelle die DSC Konfigurationsdateien"
. $global:root\runbook.ps1

$configDir = Join-Path -Path $global:root -ChildPath "Configuration"
New-Item -Path $configDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
Remove-Item -Path "$configDir\*.*" -ErrorAction SilentlyContinue
[array]$dscFiles = VMRunbook -ConfigurationData $configData -OutputPath $configDir

$logJobs = @()
foreach ($node in $configData.AllNodes) {

    if (!(Get-VM -Name $($node.NodeName) -ErrorAction SilentlyContinue)) {  
        
        Write-Host "Deploye $($node.NodeName)"        
        
        $node.NICS | ? {$_ -ne $null} | % { New-VMNic -name $_.SwitchName -type $_.SwitchType -nic $_.NIC}
        $files = @()
        $node.Roles | % { $files += $_.GetFiles()}
        $node.Applications | % { $files += $_.SourcePath }
        Deploy-VM   -vmName $node.NodeName `
                    -vhdxFile $node.VhdxPath `
                    -organization $node.DomainName `
                    -dscFile $dscFiles.Where( {$_.BaseName -eq $node.NodeName} ).FullName `
                    -enableDSCReboot `
                    -files $files `
                    -ram $node.RAM `
                    -diskSize $node.DiskSize `
                    -cores $node.Cores `
                    -systemLocale $node.SystemLocale `
                    -NICs $node.NICS `
                    -online $node.Online `
                    -dscModules $node.Roles.DscModules

        $logJobs += Show-VMLog -vmName $node.NodeName -cred $node.LocalCredentials
    }
    else {

        Write-Host "$($node.NodeName) ist schon vorhanden. Überpringe.."
    }
}


if ($MyInvocation.Line -like "*&*") {

    $null = Read-Host -Prompt 'Enter drücken ('

    if ($logJobs) {

        Hide-Console

        $ready = $false

        do {
            $logJobs | % {

                if (!($_.IsCompleted)) {

                    $ready = $true
                    Start-Sleep 5
                }
            }
        }
        until ($ready)

        Stop-Process $PID
    }
}
