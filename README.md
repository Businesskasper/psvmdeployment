# psvmdeployment
I use this project to deploy virtual environments on my local machine using hyper-v, powershell and desired state configuration. This includes automated updating of the deployment workbench and creating base images, building role based declarative environment configurations and the deploying and state monitoring the virtual machines.

The setup is built around [Powershell DSC](https://docs.microsoft.com/de-de/powershell/dsc/overview?view=dsc-1.1). If you invoke ``run.ps1``, the defined roles and applications in [ps/roles.ps1](ps/roles.ps1) are built. Then configData.ps1 is parsed (as described [here](https://docs.microsoft.com/de-de/powershell/dsc/configurations/configdata?view=dsc-1.1)) and DSC Configurations are created. For each dsc node configuration a corresponding vm is deployed.<br><br>

## Getting started
1. [Install prerequisites](docs/1_prerequisites.md)
2. [Build a base image](docs/2_base_image.md)
3. [Download sources](docs/3_download_sources.md)
4. [Define apps and roles](docs/4_define_apps_and_roles.md)
5. [Define nodes](docs/5_define_nodes.md)
6. [Deploy nodes](docs/6_deploy_nodes.md)


