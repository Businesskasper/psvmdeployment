class NodeBase {
    [void]Validate() {
        throw [System.NotImplementedException]::new()
    }

    [hashtable] ToNodeHash() {
        throw [System.NotImplementedException]::new()
    }
}

class NodeDefaults : NodeBase {
    [string]$DomainName
    [String]$DomainNetBios
    [string]$SystemLocale
    [PSCredential]$DomainCredentials
    [PSCredential]$LocalCredentials

    [hashtable] ToNodeHash() {
        $nodeAsHash = [Hashtable]@{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
            RebootNodeIfNeeded          = $true
        }
        $props = $this.GetType().GetProperties()
        foreach ($prop in $props) {
            $nodeAsHash[$prop.Name] = $prop.GetValue($this)
        }
        return $nodeAsHash
    }

    [void] Validate() {
        if ((-not [String]::IsNullOrWhiteSpace($this.DomainName)) -and $null -eq $this.DomainCredentials) {
            throw [Exception]::new("Property `"DomainName`" is set, but no DomainCredentials were provided")
        }
        elseif (([String]::IsNullOrWhiteSpace($this.DomainName)) -and $null -ne $this.DomainCredentials) {
            throw [Exception]::new("Property `"DomainCredentials`" ist set, but no DomainName has been provided")
        }
    }
}

class Node : NodeBase {
    [string]$NodeName
    [PSCredential]$LocalCredentials
    [NodeRole[]]$Roles
    [Nic[]]$NICs
    [Application[]]$Applications
    [string]$VhdxPath
    [string]$OSType
    [Int64]$RAM
    [Int64]$DiskSize
    [int]$Cores
    [boolean]$JoinDomain
    [boolean]$Online


    [hashtable] ToNodeHash() {
        $nodeAsHash = [Hashtable]@{}
        $props = $this.GetType().GetProperties()
        foreach ($prop in $props) {
            $nodeAsHash[$prop.Name] = $prop.GetValue($this)
        }
        return $nodeAsHash
    }
    
    [void] Validate() {
        if ([String]::IsNullOrWhiteSpace($this.NodeName)) {
            throw [Exception]::new("Property `"NodeName`" must be set")
        }
        elseif ($this.NodeName.Length -gt 15) {
            throw [Exception]::new("Property `"NodeName`" must have a max length of 15")
        }
    }
}

class NodeConfiguration {
    [NodeDefaults]$NodeDefaults
    [Node[]]$AllNodes

    [Hashtable] ToConfigData() {
        $configData = [Hashtable]@{
            AllNodes = @($this.NodeDefaults.ToNodeHash())
        }

        foreach ($node in $this.AllNodes) {
            $configData["AllNodes"] += $node.ToNodeHash()
        }

        return $configData
    }
}