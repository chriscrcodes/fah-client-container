# Run and deploy Folding@Home container to an Azure Container Instance (NVIDIA GPU-backed)

## Fill variables

- `$subscriptionID = ""`  
- `$location = "westus2"`  
- `$resourceGroupName = "container-rg"`  
- `$containerRegistryName = "myacr"`  
- `$containerRegistrySku = "Basic"`  
- `$dockerImageName = "fahclientgpu"`  
- `$dockerImageTag = "u18.04-c9.2-f7.6.13"`  

## Run commands with Azure CLI/PowerShell

1. Login to Azure  
`az login`
2. Select Subscription  
`az account set --subscription "$($subscriptionID)"`
3. Create Resource Group  
`az group create --name "$($resourceGroupName)" --location "$($location)"`
4. Create Container Registry  
`az acr create --resource-group "$($resourceGroupName)" --name "$($containerRegistryName)" --sku "$($containerRegistrySku)"`
5. Login to Container Registry  
`az acr login --name "$($containerRegistryName)"`
6. Move to the same folder as Dockerfile
7. Build Docker image (in the same folder as Dockerfile)  
`docker build -t "$($dockerImageName)" .`
8. Tag Docker image  
`docker tag "$($dockerImageName):latest" "$($containerRegistryName).azurecr.io/$($dockerImageName):$($dockerImageTag)"`
9. Push Docker image to Azure Container Registry  
`docker push "$($containerRegistryName).azurecr.io/$($dockerImageName):$($dockerImageTag)"`
10. Create Azure Service Principal with pull rights on Azure Container Registry

    - `$acrScope = az acr show --name "$($containerRegistryName)" --query id --output tsv`
    - `$appPassword = az ad sp create-for-rbac --name "http://$($containerRegistryName)-pull" --scopes "$($acrScope)" --role acrpull --query password --output tsv`
    - `$appId = az ad sp show --id "http://$($containerRegistryName)-pull" --query appId --output tsv`

11. Note $appId and $appPassword values

12. Move to the same folder as aci-gpu.yaml file

13. Replace values into brackets and save file changes
    - Line 5: `server: [ContainerRegistryName]` => `$containerRegistryName`
    - Line 6: `username: [ClientId]` => `$appId`
    - Line 7: `password: [ClientSecret]` => `$appPassword`
    - Line 9: if you want to change the GPU, check [here](https://docs.microsoft.com/en-us/azure/container-instances/container-instances-gpu#about-gpu-resources) the list of available NVIDIA GPUs. As of writing: K80, P100, V100
    - Line 11: `image: [ContainerRegistryName].azurecr.io/[DockerImageName]:[Tag]` => `$containerRegistryName`, `$dockerImageName`, `$dockerImageTag`
    - Line 28: `dnsNameLabel: [DNSName]` => public DNS name to connect to Azure Container Instance (you can use [HFM.NET](https://github.com/harlam357/hfm-net) for progress monitoring)

14. Create Azure Container Instance based on YAML file  
`az container create --resource-group $resourceGroupName --file .\aci-gpu.yaml`

15. Container Instance creation can take up to 30 minutes, depending on Azure Region machines availability.

Thanks for helping Science!
