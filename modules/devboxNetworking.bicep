
param prefix string 
param location string = resourceGroup().location


param subnetName string = 'sn-devpools'
param vnetAddress string = '10.0.0.0/24'
param subnetAddress string = '10.0.0.0/24'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-${prefix}-${location}'
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
  name: 'con-${prefix}-${location}'
  location: location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: '${virtualNetwork.id}/subnets/${subnetName}'
  }
}



output networkConnectionName string = networkconnection.name
output networkConnectionId string = networkconnection.id

