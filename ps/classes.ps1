﻿enum InstallType {

    MSI
    EXE
}


class Application {

    [InstallType]$InstallType
    [string]$AppName
    [hashtable]$SourcePath
    [string]$BinaryPath
    [string[]]$Arguments
    [int[]]$ExitCodes
    [string]$TestPath
    [hashtable]$Shortcut

    [void] Validate() {

        if ($this.InstallType -eq [InstallType]::EXE -and $this.Arguments.Count -eq 0) {

            throw [Exception]::new("Für .exe Setups müssen Installationsparameter angegeben werden") 
        }
        
        if (-not (Test-Path ([System.IO.Path]::Combine($this.Dir, $this.SetupFile)))) {

            throw [Exception]::new("Installer nicht gefunden") 
        }

        if ($this.InstallType -eq [InstallType]::MSI -and (-not $this.SetupFile.EndsWith(".msi"))) {

            throw [Exception]::new("Für MSI Installer müssen MSI Pakete angegeben werden") 
        }
    }
}


class PsModule {
    
    [ValidateNotNullOrEmpty()]
    [string] $Name

    [ValidateNotNullOrEmpty()]
    [Version] $RequiredVersion

    [ValidateNotNullOrEmpty()]
    [string] $ModuleBase


    [void] Validate() {

        $spec = [Microsoft.PowerShell.Commands.ModuleSpecification]::new(@{
                ModuleName = $this.Name
                RequiredVersion = $this.RequiredVersion.ToString()
        })

        if (-not (Get-Module -ListAvailable -FullyQualifiedName $spec)) {

            #Module not installed
            Write-Host -Object "Module `"$($this.Name)`" was not found!"

            if (Test-Path ([System.IO.Path]::Combine($this.ModuleBase, $this.Name, $this.RequiredVersion.ToString()))) {

                #Copy it from specified Path
                Write-Host "Copying from $($this.ModuleBase)"
                Copy-Item -Path ([System.IO.Path]::Combine($this.ModuleBase, $this.Name, $this.RequiredVersion.ToString())) -Destination ([System.IO.Path]::Combine("C:\Program Files\WindowsPowerShell\Modules\" , $this.Name, $this.RequiredVersion.ToString())) -ErrorAction Stop -Force -Recurse
            }
            else {

                Write-Host "Downloading.."
                $module = Find-Module -Name $this.Name -RequiredVersion $this.RequiredVersion -ErrorAction Stop
                $module | Save-Module -Path $this.ModuleBase -Force
                $module | Install-Module -Force 
            }
        }
    }
}


class NodeRole {

    [ValidateNotNullOrEmpty()]    
    [string] $Name

    [Application[]] $Applications

    [DscModule[]] $DscModules

    [Hashtable[]] $Files

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

    [hashtable[]] GetFiles() {

        $returnFiles = @()

        foreach ($app in $this.Applications) {

            $returnFiles += $app.SourcePath
        }

        foreach ($file in $this.Files) {

            $returnFiles += $file
        }

        return $returnFiles
    }
}