@description('The location all resources will be deployed to')
param location string = resourceGroup().location

@description('An array of additional regions to replicate images to')
param additionalLocations array = []

@description('The name of the image to be created')
param imageName string

@description('The name of the image publisher')
param imagePublisher string 

@description('The name of the Compute Gallery')
param computeGalleryName string

@description('The name of the Dev Center')
param devCenterName string

@description('Dev Center Managed Identity Name')
param devCenterManagedIdName string

@description('A prefix to add to the start of all resource names. Note: A "unique" suffix will also be added')
param prefix string = 'pocdevboxcustom'

param installScript array = split(loadTextContent('../imageBuilderScripts/vscode-developer.ps1'), ['\r','\n'])

@description('Tasks to install on the vm')
param customize array = [
  {
    type: 'PowerShell'
    name: 'VSCode with Node Setup'
    inline: installScript
  }
]
param guid string = newGuid()
var uniqueName = take('${prefix}_${imageName}_${guid}',64)


// Todo: make params
var imageOffer = prefix
var imageSku = '1-0-0'
var imageBuilderSku = 'Standard_D8ds_v4'
var imageBuilderDiskSize = 256
var runOutputName = '${imageName}_output'
var tags = {
  'Demo-Name': 'DevBoxCustomImage'
}

resource devCenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devCenterName
}

resource devCenterManagedId 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: devCenterManagedIdName
}


resource computeGallery 'Microsoft.Compute/galleries@2022-03-03' = {
  name: computeGalleryName
  location: location
  properties: {}
  tags: tags

resource image 'images@2022-03-03' = {
  name: imageName
  location: location
  properties: {
    features: [
      {
        name: 'SecurityType'
        value: 'TrustedLaunch'
      }
    ]
    identifier: {
      offer: imageOffer
      publisher: imagePublisher
      sku: imageSku
    }
    osState: 'Generalized'
    osType: 'Windows'
    hyperVGeneration: 'V2'
  }
  tags: tags
}
}

//Associate Compute Gallery Image with Dev Center
resource devCenterGallery 'Microsoft.DevCenter/devcenters/galleries@2022-11-11-preview' = {
  name: computeGallery.name
  parent: devCenter
  properties: {
    galleryResourceId: computeGallery.id
  }
}

resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: uniqueName
  location: location
  properties: {
    buildTimeoutInMinutes: 100
    vmProfile: {
      vmSize: imageBuilderSku
      osDiskSizeGB: imageBuilderDiskSize
    }
    source: {
      type: 'PlatformImage'
      publisher: 'MicrosoftWindowsDesktop'
      offer: 'Windows-11'
      sku: 'win11-21h2-avd'
      version: 'latest'
    }
    // This is where we customise the image
    customize: customize
    distribute: [
      {
        galleryImageId: computeGallery::image.id
        replicationRegions: concat([location], additionalLocations)
        runOutputName: runOutputName
        artifactTags: {
          source: 'azureVmImageBuilder'
          baseosimg: 'win11multi'
        }
        type: 'SharedImage'
      }
    ]
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${devCenterManagedId.id}': {}
    }
  }
  tags: tags
}

var pwshBuildCommand = 'Invoke-AzResourceAction -ResourceName "${uniqueName}" -ResourceGroupName "${resourceGroup().name}" -ResourceType "Microsoft.VirtualMachineImages/imageTemplates" -ApiVersion "2020-02-14" -Action Run -Force'

@description('To invoke the AIB build step locally, in PowerShell, use this command.')
output imageBuildPwshCommand string = pwshBuildCommand

@description('This resource invokes a command to start the AIB build')
resource imageTemplate_build 'Microsoft.Resources/deploymentScripts@2020-10-01' =  {
  name: '${uniqueName}-build-trigger'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${devCenterManagedId.id}': {}
    }
  }
  dependsOn: [
    imageTemplate
    devCenterManagedId
  ]
  properties: {
    forceUpdateTag: guid
    azPowerShellVersion: '6.2'
    scriptContent: pwshBuildCommand
    timeout: 'PT1H'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}
