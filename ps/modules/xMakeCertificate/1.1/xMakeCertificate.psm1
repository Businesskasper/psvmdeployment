enum Ensure {  
    Absent
    Present
}

enum CertificateType {
    Root
    Client
    Web
}

[DscResource()]
class xMakeCertificate {
    [DscProperty(Key)]
    [CertificateType]$Type

    [DscProperty(Mandatory)]
    [Ensure]$Ensure
     
    [DscProperty(Mandatory)]
    [string]$CommonName

    [DscProperty()]
    [string]$Store

    [DscProperty()]
    [string[]]$SubjectAlternativeNames
    
    [DscProperty()]
    [string]$SignerPath

    [DscProperty()]
    [PSCredential]$SignerPassword

    [DscProperty()]
    [string] $ExportPath

    [DscProperty()]
    [PSCredential]$PFXPassword

    [DscProperty(NotConfigurable)]
    [Nullable[bool]] $IsCompliant

    
    [void] Set() {
        if ($this.Ensure -eq [Ensure]::Present) {
            $cert = $this.makeCertificate($this)

            if ($this.ExportPath -and $this.ExportPath.EndsWith(".pfx") -and $this.PFXPassword) {
                md $(Split-Path -Path $this.ExportPath -Parent) -Force -ea 0
                Export-PfxCertificate -Cert $cert -Password $this.PFXPassword.Password -FilePath "filesystem::$($this.ExportPath)"
            }
            elseif ($this.ExportPath -and $this.ExportPath.EndsWith(".cer") -and !$this.PFXPassword) {
                md $(Split-Path -Path $this.ExportPath -Parent) -Force -ea 0
                Export-Certificate -Cert $cert -FilePath "filesystem::$($this.ExportPath)"
            }

            if ($this.Store.ToLower() -notlike "cert:\*\my") {
                Move-Item $cert.PSPath -Destination $this.Store -Force
            }
            if ($this.Type -eq [CertificateType]::Web -and $this.SignerPath.Length -le 1) {
                $rootStore = New-Object  -TypeName System.Security.Cryptography.X509Certificates.X509Store  -ArgumentList "root", "LocalMachine"
                $rootStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
                $rootStore.Add($cert)
                $rootStore.Close()
            }
        }      
    }        
    
    [bool] Test() {   
        return $this.testCompliance($this)
    }    

    [xMakeCertificate] Get() {     
        $this.IsCompliant = $this.testCompliance($this)
        return $this   
    }

    [bool] testCompliance ([xMakeCertificate]$xCertificate) {
        $return = $false
        Get-ChildItem -Path $xCertificate.Store | ? {$_.Subject -eq $("CN=" + $xCertificate.CommonName)} | % {

            if (!$return) {
                if ($xCertificate.SubjectAlternativeNames) {
                    if (!(Compare-Object -ReferenceObject $xCertificate.SubjectAlternativeNames -DifferenceObject $_.DnsNameList.Unicode)) {
                        $return = $true
                    }      
                }
                else {
                    $return = $true
                }
              
                if ($xCertificate.ExportPath) {
                    if (!(Test-Path -Path "filesystem::$($this.ExportPath)")) {
                        $return = $false
                    }
                }     
            }          
        }

        return $return
    }
  

    [System.Security.Cryptography.X509Certificates.X509Certificate2] makeCertificate ([xMakeCertificate]$xCertificate) {
        $arguments = @{
            Subject           = $xCertificate.CommonName
            HashAlgorithm     = "sha256"
            KeyLength         = 2048
            NotAfter          = (Get-Date).AddMonths(24) 
            CertStoreLocation = "Cert:\LocalMachine\My"
        }

        if ($this.SubjectAlternativeNames) {
            $arguments += @{
                DnsName = $xCertificate.SubjectAlternativeNames
            }
        }

        if ($xCertificate.Type -eq [CertificateType]::Root) {
            $arguments += @{     
                KeyUsage         = "KeyEncipherment", "DigitalSignature", "CertSign", "cRLSign"
                KeyusageProperty = "All"
                TextExtension    = @("2.5.29.19 ={critical} {text}ca=1&pathlength=3")
                KeySpec          = "KeyExchange"
            }
        }
        elseif ($xCertificate.Type -eq [CertificateType]::Client) {
            $arguments += @{
                KeyUsage = "KeyEncipherment", "DigitalSignature"
                KeySpec  = "KeyExchange"
            }
        }

        $signer = $null
        if ($xCertificate.SignerPath -and $xCertificate.SignerPassword) {
            $signer = Import-PfxCertificate -FilePath $xCertificate.SignerPath -Password $xCertificate.SignerPassword.Password -CertStoreLocation Cert:\LocalMachine\My
            $arguments += @{
                Signer = $signer
            }
        }

        try {
            return New-SelfSignedCertificate @arguments
        }
        finally {
            if ($xCertificate.SignerPath -and $xCertificate.SignerPassword) {
                Remove-Item -Path $signer.PSPath
            }
        }
    }
}