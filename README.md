## Microsoft Dev Box Quickstart

- [What is Microsoft Dev Box?](https://learn.microsoft.com/en-us/azure/dev-box/overview-what-is-microsoft-dev-box)
- [DevBox QuickStart](https://github.com/luxu-ms/Devbox-ADE-Infra/tree/main)

# Custom DevBox Image

## Requirements

- Install the AZ CLI tool
- Connect to your Azure tenant using `az login`
- Connect to the appropriate subscription `az account set --subscription $subscriptionID`
- User who has logged in into az cli should have Owner permission as this demo assigns an RBAC role to a managed identity
- Ensure that the correct resource providers are enabled on the subscription [resource provider docs](https://learn.microsoft.com/en-us/azure/dev-box/how-to-customize-devbox-azure-image-builder#create-a-windows-image-and-distribute-it-to-azure-compute-gallery)

## Clone the repository

```bash
git clone https://github.com/shksin/devbox-custom-image
```

## Create Dev Center

Create a resource group in Azure for Microsoft Dev Box Dev Center. Change the values of the variables below to suit your environment.
```bash
RG_DC=rg-poc-devcenter
LOCATION=australiaeast

#Get the deploying users id for RBAC assignments
DEPLOYINGUSERID=$(az ad signed-in-user show --query id -o tsv)

#Create resource group
az group create -n $RG_DC -l $LOCATION

#Change the values of the variables below to suit your environment. 
devCenterName=myDevCenter
projectTeamName=frontend

#Create devcenter common components
az deployment group create -g $RG_DC -f modules/devCenter.bicep -p devCenterName=$devCenterName projectTeamName=$projectTeamName devboxProjectAdmin=$DEPLOYINGUSERID
```

Following resources are created in Dev Center resource group:
- **Dev center:** A collection of Projects that require similar settings. 
- **Project:**  Represents a team or  or business function within the organization.
- **DevBoxProjectAdmin:** The user who is responsible for managing the project. 

## Custom Image Build

The scripts that Azure Image Builder will use to build the image template for DevBox are in the `imageBuilderScripts` directory.
- **vscode-developer.ps1:** A sample script to deploy tools for frontend developers like vscode, github, node etc. 


## Create Custom Image for DevBox Definition

Create a resource group in Azure for Microsoft Dev Box Dev Center. Change the values of the variables below to suit your environment.
```bash
RG_CUSTOMIMAGE=rg-devbox-custom-images
LOCATION=australiaeast

#Create resource group
az group create -n $RG_CUSTOMIMAGE -l $LOCATION

#Change the values of the variables below to suit your environment. 
imagePublisher=myOrganisation

#Create devcenter common components
az deployment group create -g $RG_CUSTOMIMAGE -f modules/customImage.bicep  -p imagePublisher=$imagePublisher 
```
<br> **Note:** The Image build process is slow and can take upto 30 minutes. <br>
Navigate to the `Image Template` created and check the status of the image build. <br>
    ![image](images/customImageBuildInProgress.png) <br>

Once the image build is complete, the status should update to succeeded.<br>
     ![image](images/customImageBuildSuccess.png)



## Resources Deployed

Following resources are created in Custom Image resource group:
- **Azure Compute Gallery:** A gallery for Virtual Machine images to be stored and distributed for consumption.
- **VM Image Definition:** The Image definitions that are versioned and publish to the Compute Gallery.
- **Image Template:** Azure Image Builder template used to create a Virtual Machine image that can be used by DevBox.
- **Deployment Script:** Triggers the `image template build` to create a new image.
- **Managed Identity:** The identity used by the Virtual Machine Image definition to spin-up a Virtual Machine, Virtual Network and create an image.

