# psvmdeployment
Automated vm deployment using Hyper-V, Powershell and Desired State Configuration. Includes tooling for automated updating of the deployment bench, creation of base images, building of role based, declarative environment configurations and the deployment and state monitoring of the virtual machines.

The setup is built around [Powershell DSC](https://docs.microsoft.com/de-de/powershell/dsc/overview?view=dsc-1.1). After invoking [run.ps1](./run.ps1), all defined apps, roles and DSC config data and configuration get parsed. Each node is deployed and injected with its configuration and all required modules and binaries. <br><br>

## Getting started
1. [Install prerequisites](docs/1_prerequisites.md)
2. [Build a base image](docs/2_base_image.md)
3. [Download sources](docs/3_download_sources.md)
4. [Define apps and roles](docs/4_define_apps_and_roles.md)
5. [Define nodes](docs/5_define_nodes.md)
6. [Deploy nodes](docs/6_deploy_nodes.md)


