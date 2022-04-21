# Download sources

The project has several predefined roles and applications which can be used to deploy virtual machines.
The applications binaries must be placed in the ```sources``` directory. The binaries itself are not checked in to git. However, for each applicaion there is am update.ps1 file incldued which will download all required apps. You can either run those files, or invoke [ps/update.ps1](../ps/updateWorkbench.ps1) to trigger all downloads.