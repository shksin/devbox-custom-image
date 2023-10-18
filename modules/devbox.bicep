param location string = resourceGroup().location

@description('For a multi region scenarios, new vnets and pools will be created for the project')
param extraLocations array = []

@description('The name of the existing DevCenter')
param devcenterName string

@description('The name of the project team')
param projectTeamName string 

@description('The name of the devbox definition')
param devboxDefinitionName string 

@description('The time to shutdown the devbox. This is in the timezone of the region where the devbox is located. HH:mm format.')
param shutdownTime string = '19:00'

@description('A list of Azure locations and their time zone. This is used to create the schedule for the devbox shutdown.')
var regionTimeZones = loadJsonContent('azure-region-lookup.json')

@description('All locations, in one array')
var allLocations = concat([location],extraLocations)

resource devCenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devcenterName
}

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' existing = {
  name: projectTeamName
}

resource devboxDefinition 'Microsoft.DevCenter/devcenters/devboxdefinitions@2022-11-11-preview' existing = {
  name: devboxDefinitionName
}
module networkingLocations 'devboxNetworking.bicep' = [for (loc, i) in allLocations: {
  name: '${deployment().name}-Networking-${loc}'
  params: {
    devcenterName: devCenter.name
    location: loc
  }
}]


resource frontendProjectPool 'Microsoft.DevCenter/projects/pools@2023-01-01-preview' =  [ for (loc, i) in allLocations: {
  name: '${projectTeamName}-pool-${loc}'
  location: location
  parent: project
  properties: {
    devBoxDefinitionName: devboxDefinition.name
    licenseType: 'Windows_Client'
    localAdministrator: 'Enabled'
    networkConnectionName: networkingLocations[i].outputs.attachedNetworkName
  }
}]

@description('This loop expression might look complex, but it is simply just creating a schedule for every pool in every region')
resource scheduleStop 'Microsoft.DevCenter/projects/pools/schedules@2023-01-01-preview' =  [ for (loc, i) in allLocations: {
  name: '${projectTeamName}/${projectTeamName}-${loc}/default'
  dependsOn: [
    frontendProjectPool[i]
  ]
  properties: {
    frequency: 'Daily'
    state: 'Enabled'
    type: 'StopDevBox'
    timeZone: regionTimeZones[loc]
    time: shutdownTime
  }
}]
