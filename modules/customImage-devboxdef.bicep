@description('The Azure region where resources in the template should be deployed.')
param location string = resourceGroup().location
param devCenterName string
param computeGalleryName string
param imageName string

@allowed(['ssd_256gb', 'ssd_512gb', 'ssd_1024gb'])
param storage string = 'ssd_256gb'

param imageSku string = 'general_i_8c32gb256ssd_v2' // general instance 8core 32gb ram 256gb ssd 

resource devCenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devCenterName
}

resource devCenterGallery 'Microsoft.DevCenter/devcenters/galleries@2022-11-11-preview' existing = {
  name: computeGalleryName
}

resource galleryimage 'Microsoft.DevCenter/devcenters/galleries/images@2022-11-11-preview' existing = {
  name: imageName
  parent: devCenterGallery
}

//Create Dev Box Definition
resource devboxdef 'Microsoft.DevCenter/devcenters/devboxdefinitions@2022-11-11-preview' = {
  name: imageName
  parent: devCenter
  location: location
  properties: {
    sku: {
      name: imageSku
    }
    imageReference: {
      id: galleryimage.id //the resource-id of a Microsoft.DevCenter Gallery Image
    }
    osStorageType: storage
    hibernateSupport: 'Disabled'
  }
}
output definitionName string = devboxdef.name
