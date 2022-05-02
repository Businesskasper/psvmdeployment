enum InstallType {
    MSI
    EXE
}

class Application {

    [ValidateNotNullOrEmpty()]
    [InstallType]$InstallType

    [ValidateNotNullOrEmpty()]
    [string]$AppName
    
    [ValidateNotNullOrEmpty()]
    [Binary]$SourcePath
    
    [ValidateNotNullOrEmpty()]
    [string]$BinaryPath
    
    [string[]]$Arguments
    
    [ValidateNotNullOrEmpty()]
    [int[]]$ExitCodes
    
    [ValidateNotNullOrEmpty()]
    [string]$TestPath
    
    [hashtable]$Shortcut

    [void] Validate() {
        if ($this.InstallType -eq [InstallType]::EXE -and $this.Arguments.Count -eq 0) {
            throw [Exception]::new("Installation parameters must be provided for .exe setups") 
        }
        
        if (-not (Test-Path $this.SourcePath.Source)) {
            throw [Exception]::new("Binary not found") 
        }

        if ($this.InstallType -eq [InstallType]::MSI -and (-not $this.BinaryPath -like "*msiexec.exe*")) {
            throw [Exception]::new("A MSI package must be specified for .msi setups") 
        }
    }
}