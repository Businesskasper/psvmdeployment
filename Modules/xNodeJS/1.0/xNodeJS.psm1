enum Ensure
{
    Absent
    Present
}

[DscResource()]
class xNodeJS
{

    [DscProperty(Key)]
    [string]$MajorVersion
        
    [DscProperty(Mandatory)]
    [Ensure] $Ensure


    [void] Set()
    {
        $i = 0
        if($this.MajorVersion -ne 'LatestStable' -and -not ([int]::TryParse($this.MajorVersion, [ref]$i))) {

            throw [Exception]::new("$($this.MajorVersion) is not a valid argument for `"MajorVersion`"")
        }

        if ($this.Ensure -eq [Ensure]::Present) {

            $versions = Invoke-WebRequest -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing | ConvertFrom-Json
            $versions.ForEach({$_.version = [Version]::new($_.version.ToString().TrimStart("v"))}) 
            
            if ($this.MajorVersion -eq "LatestStable") {

                $version = $versions | Sort-Object version -Descending | ? {$_.lts -ne $false -and $_.files -contains "win-x64-msi"} | select -First 1
            }
            else {

                $version = $versions | Sort-Object version -Descending | ? {$_.version.Major -eq $this.MajorVersion -and $_.files -contains "win-x64-msi"} | select -First 1
            }

            #Set up workingdir
            $workingDir = [System.IO.Path]::Combine($env:temp, "NodeWorkingDir")
            if (Test-Path $workingDir) {
            
                Remove-Item -Path $workingDir -Recurse -Force -Confirm:$false -ea 0
            }
            New-Item -Path $workingDir -ItemType Directory -Force -Confirm:$false

            #Download nodejs
            Invoke-WebRequest -Uri "https://nodejs.org/dist/v$($version.version.ToString())/node-v$($version.version.ToString())-x64.msi" -OutFile ([System.IO.Path]::Combine($workingDir, "node-v$($version.version.ToString())-x64.msi")) -UseBasicParsing

            #Install
            $install = Start-Process -FilePath C:\windows\system32\msiexec.exe -ArgumentList @("/i", ([System.IO.Path]::Combine($workingDir, "node-v$($version.version.ToString())-x64.msi")), "/q") -Wait -PassThru

            if ($install.ExitCode -ne 0) {

                throw [Exception]::new("NodeJS setup exited with exit code $($install.ExitCode)")
            }

        }
    }
    
    [bool] Test()
    {        
        return $this.IsInstalled()
    }    
    
    [xNodeJS] Get()
    {        
        $this.Ensure = $this.IsInstalled()
        return $this 
    }    

    [bool] IsInstalled() {

        if (-not (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{F62C0E94-FBB4-4009-9941-6271BD2EBCEF}")) {

            return $false
        }

        $regItem = Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{F62C0E94-FBB4-4009-9941-6271BD2EBCEF}"
        
        if ($this.MajorVersion -ne 'LatestStable') {

            return $regItem -ne $null -and $regItem.GetValue('VersionMajor') -eq $this.MajorVersion
        }

        return $regItem -ne $null
    }
}