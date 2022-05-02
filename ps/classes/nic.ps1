Add-Type -Language CSharp `
    -ReferencedAssemblies @('C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Microsoft.HyperV.PowerShell.Objects\v4.0_10.0.0.0__31bf3856ad364e35\Microsoft.HyperV.PowerShell.Objects.dll') `
    -TypeDefinition @"

public abstract class Nic
{
    public string SwitchName { get; set; }
    public bool DHCP { get; set; }
    public string IPAddress { get; set; }
    public string SubnetCidr { get; set; }
    public string DNSAddress { get; set; }
    public abstract Microsoft.HyperV.PowerShell.VMSwitchType SwitchType { get; }
}

public class ExternalNic : Nic
{
    public string Nic { get; set; }

    private Microsoft.HyperV.PowerShell.VMSwitchType _SwitchType;
    public override Microsoft.HyperV.PowerShell.VMSwitchType SwitchType { get { return this._SwitchType; } }

    public ExternalNic() {
        this._SwitchType = Microsoft.HyperV.PowerShell.VMSwitchType.External;
    }
}

public class InternalNic : Nic
{
    private Microsoft.HyperV.PowerShell.VMSwitchType _SwitchType;
    public override Microsoft.HyperV.PowerShell.VMSwitchType SwitchType { get { return this._SwitchType; } }

    public InternalNic() {
        this._SwitchType = Microsoft.HyperV.PowerShell.VMSwitchType.Internal;
    }
}

public class PrivateNic : Nic
{
    private Microsoft.HyperV.PowerShell.VMSwitchType _SwitchType;
    public override Microsoft.HyperV.PowerShell.VMSwitchType SwitchType { get { return this._SwitchType; } }

    public PrivateNic() {
        this._SwitchType = Microsoft.HyperV.PowerShell.VMSwitchType.Private;
    }
}

"@
