param location string = resourceGroup().location
param devcenterName string

param subnetName string = 'subnet-devpools'
param vnetAddress string = '10.0.0.0/16'
param subnetAddress string = '10.0.0.0/24'

@description('The name of a new resource group that will be created to store some Networking resources (like NICs) in')
param networkingResourceGroupName string = '${resourceGroup().name}-networking-${location}'

resource devCenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devcenterName
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-${devcenterName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddress
        }
      }
    ]
  }
}

resource networkconnection 'Microsoft.DevCenter/networkConnections@2022-11-11-preview' = {
  name: 'network-con-${devcenterName}'
  location: location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: '${virtualNetwork.id}/subnets/${subnetName}'
    networkingResourceGroupName: networkingResourceGroupName
  }
}

resource attachedNetwork 'Microsoft.DevCenter/devcenters/attachednetworks@2022-11-11-preview' = {
  name: 'dc-con-${devcenterName}'
  parent: devCenter
  properties: {
    networkConnectionId: networkconnection.id
  }
}

output networkConnectionName string = networkconnection.name
output networkConnectionId string = networkconnection.id
output attachedNetworkName string = attachedNetwork.name
