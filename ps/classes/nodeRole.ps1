class NodeRole {

    [ValidateNotNullOrEmpty()]    
    [string] $Name

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

        foreach ($file in $this.Files) {
            $allFiles += $file
        }

        return $allFiles
    }
}