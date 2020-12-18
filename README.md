# psvmdeployment

Automated vm environment creation using powershell and desired state configuration.
<br><br>

## the purpose of this project

I use this project to deploy virtual environments on my local hyper-v machine. This includes the whole process from automated creation of up-to-date base images, parsing of role - based declarative environment configurations to the deployment and state monitoring of the virtual machines.

The scripts (especially the DSC Modules I created) can be used in many ways. Feel free to give me feedback!
<br><br>

## how it works

The setup is built around [Powershell DSC](https://docs.microsoft.com/de-de/powershell/scripting/dsc/overview/overview?view=powershell-7). If you invoke ``run.ps1``, the defined roles in [./ps/roles.ps1](./ps/roles.ps1) including applications. Then configData.ps1 is getting parsed (as described [here](https://docs.microsoft.com/de-de/powershell/scripting/dsc/configurations/configdata?view=powershell-7)) and DSC Configurations are created. For each dsc configuration a corresponding node is getting deployed.<br>

Using this project, you can

1. Update your deployment workbench (including isos and applications).
2. Define reusable roles which you can assign to your nodes.
2. Define and deploy standardized multi node environments. I use this to create encapsulated testing environments, for example with a dedicated domain controller and clients.
3. Create up-to-date (OS and Software) virtual machines. I use this to create a development machine for each project I work on, with the right Node.js or .Net Version installed.
<br><br>

## what you need to use it

* Hyper-V must be installed
* Powershell Get must be installed and psgallery must be set as the default provider

## how you can run it

1. Create a base image either yourself or using [./sources/images/update.ps1](./sources/images/update.ps1).

2. Restore used powershell modules since only my own modules are checked in.

3. Edit the role definition at [./ps/roles.ps1](./ps/roles.ps1). A role consists of necessary powershell (and dsc) modules, files and applications, which must be installed. Applications itself are also defined in this file. A more precise explanation can be found [here]().

4. Look at the runbook - this is where the configuration for each node is created. You can create multiple runbooks for multiple scenarios or create a big one with conditions (like mine). You can read the [microsoft docs](https://docs.microsoft.com/de-de/powershell/scripting/dsc/configurations/write-compile-apply-configuration?view=powershell-7) to get an in depth explanation.

5. Define your nodes in [./nodeDefinition.ps1](./nodeDefinition.ps1). The node definition is mapped into the [./runbook.ps1](./runbook.ps1). See the [detailed explanation](https://docs.microsoft.com/de-de/powershell/scripting/dsc/configurations/separatingenvdata?view=powershell-7).
<br><br>

6. Update your deployment workbench using [./ps/update.ps1]. This will download all required software packages and prepare them for deployment.

7. Invoke run.ps1
