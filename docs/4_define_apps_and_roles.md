# Define apps and roles

Nodes (or virtual machines) are defined in [nodeDefinition.ps1](../nodeDefinition.ps1).
A node consists of a name, general configuration data, roles and apps. 

Depending on a roles nodes, configuration blocks in [playbook.ps1](../playbook.ps1) are applied to the node.

Apps can be mapped to a specific role or to directly to a node in [nodeDefinition.ps1](../nodeDefinition.ps1).

For example: Role "SQL" may contain the applications "Microsoft SQL Server 2019" and "SQL Server Management Studio", the apps setup binaries, required powershell modules and a section in [playbook.ps1](../playbook.ps1) which installs the apps and configures the sql service to run after boot.

Check [the next section](5_define_nodes.md) on how to apply created apps and roles to nodes.

## Define an app

Apps can be added as an Object of type [Application](../ps/classes.ps1) to the "Applications" array in [roles.ps1](../ps/roles.ps1).

An Application consists of following properties:

|Property|Description|
|--------|-----------|
|```InstallType```|MSI or EXE - choose msi if your setup binary is an msi file|
|```AppName```|The display name of the app for logging|
|```SourcePath```|Mapping of the binary paths. Object of type [Binary](../ps/classes.ps1) with ```Source``` -> location of the files on the host and ```Destination``` -> where the files should be copied to on the target node|
|```BinaryPath```|Path to the setup executable. Will typically be an exe or msi file inside the ```Destination``` prop of ```SourcePath```.
|```Arguments```|Array of arguments to be executed with the ```BinaryPath```|
|```ExitCodes```|Array of exit codes the setup is allowed to exit with. Typically 0 (success) and 3010 (reboot required)|
|```TestPath```|File or registry key to check if the software is installed or the setup has to be run|
|```Shortcut```|Information about shortcuts to be created after setup. Hashtable with keys ```Exe``` -> path to the executable and ```Arguments``` -> string of arguments to launch the ```Exe``` with.|


Example for App "Visual Studio Code":
```
    [Application]@{
        Arguments   = "C:\Sources\Software\Microsoft_VS_Code\install.ps1"
        AppName     = "VS Code 2019"
        BinaryPath  = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
        ExitCodes   = @(0, 3010)
        InstallType = [InstallType]::EXE
        SourcePath  = @{
            Source      = "$($global:root)\Sources\Software\Microsoft_VS_Code"
            Destination = "C:\Sources\Software\Microsoft_VS_Code\"
        }
        Shortcut    = [Binary]@{
            Exe = "C:\Program Files\Microsoft VS Code\Code.exe"
        }
        TestPath    = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EA457B21-F73E-494C-ACAB-524FDE069978}_is1"
    }
```
<br>
## Define a role
Roles contain Applications, Files and Modules to be installed or copied to assigned nodes. Roles are also mapped to configuration blocks inside [playbook.ps1](playbook.ps1).

Roles can be added as an Object of type [NodeRole](../ps/classes.ps1) to the "Roles" array in [roles.ps1](../ps/roles.ps1).

A NodeRole consists of following properties:

|Property|Description|
|--------|-----------|
|Name|The name of the role which is used for mapping to its configuration block|
|Applications|An array of Applications which should be installed. Applications can  also be added explicitly as inside the roles configuration section|
|DscModules|Array of [PsModule](../ps/classes.ps1). Modules specified here will be copied to the nodes module directory. If the modules are not found inside the ```modules``` directory, they will be downloaded using PowerShellGet|
|Files|Folders to be copied to the node. Array of [Binary](../ps/classes.ps1)|

Example for Role "SQL":
```
[NodeRole]@{
        Name         = "SQL"
        DscModules   = @(
            [PsModule]@{
                Name            = "SqlServer"
                ModuleBase      = "$($global:root)\modules"
                RequiredVersion = [Version]::new(21, 1, 18068)
            },
            [PsModule]@{
                Name            = "SqlServerDSC"
                RequiredVersion = [Version]::new(11, 0, 0 , 0)
                ModuleBase      = "$($global:root)\modules"
            }
        )
        Files = @(
            [Binary]@{
                Source      = "$($global:root)\Sources\Software\Microsoft_SQL_Server_2019_Developer"
                Destination = "C:\Sources\Software\Microsoft_SQL_Server_2019_Developer\"
            },
            [Binary]@{
                Source      = "$($global:root)\Sources\Software\Microsoft_SSMS"
                Destination = "C:\Sources\Software\Microsoft_SSMS\"
            }
        )
        Applications = @()
    }
```
