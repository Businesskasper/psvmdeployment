enum Ensure {
    Absent
    Present
}

[DscResource()]
class xInstallExe {
    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [ValidateNotNullOrEmpty()]
    [string]$AppName

    [DscProperty(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$BinaryPath

    [DscProperty(Mandatory)]
    [string[]]$Arguments

    [DscProperty()]
    [string]$TestPath

    [DscProperty()]
    [string]$TestExpression

    [DscProperty(Mandatory)]
    [int[]]$ExitCodes

    [DscProperty()]
    [Hashtable]$Shortcut

    [DscProperty(NotConfigurable)]
    [ValidateNotNullOrEmpty()]
    [bool]$Compliant

    [void] Set() {
        $this.install($this.BinaryPath, $this.Arguments, $this.ExitCodes)

        if ($this.Shortcut -ne $null) {
            Write-Verbose -Message "Erstelle Shortcut"
            $this.makeShortcut($this.Shortcut.Exe, "C:\users\public\desktop\$($this.AppName + ".lnk")", $this.Shortcut.Parameter)
        }
    }
    

    [bool] Test() {
        return $this.isInstalled($this)
    }

    [xInstallExe] Get() {
        $results = @{}

        $results['Ensure'] = $this.Ensure
        $results['AppName'] = $this.AppName
        $results['Arguments'] = $this.Arguments
        $results['BinaryPath'] = $this.BinaryPath
        $results['ExitCodes'] = $this.ExitCodes
        $results['TestPath'] = $this.TestPath
        $results['Compliant'] = $this.isInstalled($this)

        return $results
    }


    [bool] isInstalled([xInstallExe]$obj) {
        if ($obj.TestPath) {
            return $(Test-Path $obj.TestPath)
        }
        else {
            return $(Invoke-Expression -Command ($obj.TestExpression))
        }
    }

    [bool] install([string]$binaryPath, [string[]]$arguments, [int[]]$exitCodes) {
        if (Test-Path $binaryPath) {
            $setup = Start-Process -FilePath $binaryPath -ArgumentList $arguments -Wait -PassThru
            if ($setup.ExitCode -in $exitCodes) {
                return $true
            }
        }
        return $false
    }

    [void] makeShortcut ( [string]$exe, [string]$destination, [string]$arguments ) {
        Write-Verbose "Erstelle Shortcut $($exe) nach $($destination)"
        $WshShell = New-Object -comObject WScript.Shell

        $lnk = $WshShell.CreateShortcut($destination)
        $lnk.TargetPath = $exe
        $lnk.Arguments = $arguments

        $lnk.Save()
    }

    [Hashtable] CimInstancesToHashtable([Microsoft.Management.Infrastructure.CimInstance[]] $pairs) {
        $hash = @{}
        foreach ($pair in $pairs) { 
            Write-Verbose "Konvertiere Hashtable mit $($pair.Key) = $($pair.Value)"
            $hash[$pair.Key] = $pair.Value
        }
        return $hash
    }

}


