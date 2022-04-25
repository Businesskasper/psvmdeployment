enum InstallType {
    MSI
    EXE
}

class Binary {
    [string]$Source
    [string]$Destination
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

class PsModule {
    
    [ValidateNotNullOrEmpty()]
    [string] $Name

    [ValidateNotNullOrEmpty()]
    [Version] $RequiredVersion

    [void] Validate() {

        $spec = [Microsoft.PowerShell.Commands.ModuleSpecification]::new(@{
                ModuleName      = $this.Name
                RequiredVersion = $this.RequiredVersion.ToString()
            })
        $localModule = Get-Module -ListAvailable -FullyQualifiedName $spec | select -First 1
        if ($null -eq $localModule) {
            #Module not installed
            Write-Host -Object "Module `"$($this.Name)`" was not found!"
            Write-Host "Downloading.."
            $module = Find-Module -Name $this.Name -RequiredVersion $this.RequiredVersion -ErrorAction Stop
            $module | Install-Module -Force 
        }
    }
}

class NodeRole {

    [ValidateNotNullOrEmpty()]    
    [string] $Name

    [Application[]] $Applications

    [PsModule[]] $DscModules

    [Binary[]] $Files

    [void] Validate () {
        foreach ($dscModule in $this.DscModules) {   
            $dscModule.Validate()
        } 

        foreach ($application in $this.Applications) {
            $application.Validate()
        }

        foreach ($file in $this.Files) {     
            if (-not (Test-Path -Path $file.Source -ErrorAction Stop)) {
                throw "$($file.Source) on Role `"$($this.Name)`" was not found!"
            }
        } 
    }

    [Binary[]] GetFiles() {
        $allFiles = @()

        foreach ($app in $this.Applications) {
            $allFiles += $app.SourcePath
        }

        foreach ($file in $this.Files) {
            $allFiles += $file
        }

        return $allFiles
    }
}