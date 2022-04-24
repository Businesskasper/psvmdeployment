# Define Nodes

Nodes can be defined in [nodeDefinition.ps1](../nodeDefinition.ps1).

The file returns a hashtable with one key targeting all nodes (```NodeName = "*"```) and another key per node. Examples can be found in the ```examples``` directory.

A node can be configured using following properties:

|Name|Required|Description|
|----|--------|-----------|
|NodeName|yes|The hostname of the virtual machine|
|LocalCredentials|yes|The nodes local Administrator credentials as [PSCredentials](https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.pscredential)|
|DomainCredentials|if at least one node has role "DC"|The environments domain Administrator credentials as [PSCredentials](https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.pscredential)|
|Domainname|if at least one node has role "DC"|The name of the AD Domain to create or join|
|DomainNetBios|if at least one node has role "DC"|The net bios name of the AD Domain to create or join|
|SystemLocale|yes|The keyboard layout to install|
|[PSDscAllowPlainTextPassword](https://docs.microsoft.com/en-us/powershell/dsc/configurations/configdatacredentials?view=dsc-1.1)|yes|Allow unencrypted credentials in the configuration file. Should be true in our local scenario|
|[PSDscAllowDomainUser](https://docs.microsoft.com/en-us/powershell/dsc/configurations/configdatacredentials?view=dsc-1.1)|yes|Allow domain credentials in the configuration file. Should be true in our local scenario|
|[RebootNodeIfNeeded](https://docs.microsoft.com/en-us/powershell/dsc/configurations/reboot-a-node?view=dsc-1.1)|yes|Allow the node to reboot while applying its configuration. Should be true|
|Roles|no|Array of [roles](4_define_apps_and_roles.md) to apply|
|VhdxPath|yes|Path to the [base image](2_base_image.md) to setup the node|
|OSType|no|"Standard" or "Core", depending on your base image. You can use this prop to filter configuration items in [playbook](../playbook.ps1)|
|RAM|yes|Amount of RAM in bytes|
|DiskSize|yes|Size of the disk in bytes|
|Cores|yes|Amount of cpu cores to assign|
|Online|no|The node will be plugged into Hyper-V's default virtual switch which uses NAT.|
|NICs|no|Array of [NIC's](../ps/classes.ps1) to assign to the vm. If one provided nic does not exist, it will be created during deployment|
|Export|no|If set to true, a task will be installed to the node which restores its network configuration on reboot. This is done because the network config would be lost when the virtual machine is exported and imported again|
|JoinDomain|no|If set to true, the device is joined to the Domain provided in ```DomainName```. The deployment waits for the DC node to complete and the domain to become available|