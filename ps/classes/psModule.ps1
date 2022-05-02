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