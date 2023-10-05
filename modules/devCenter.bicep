param devCenterName string
param location string = resourceGroup().location
param projectTeamName string = 'frontend'

@description('Provide the AzureAd UserId to assign project rbac for (get the current user with az ad signed-in-user show --query id)')
param devboxProjectUser string = '' 

@description('Provide the AzureAd UserId to assign project rbac for (get the current user with az ad signed-in-user show --query id)')
param devboxProjectAdmin string = ''

resource devCenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' = {
  name: devCenterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
}

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' = {
  name: projectTeamName
  location: location
  properties: {
    devCenterId: devCenter.id
  }
}

var devCenterDevBoxUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '45d50f46-0b78-4001-a660-4198cbe8cd05')
resource projectUserRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(!empty(devboxProjectUser)) {
  scope: project
  name: guid(project.id, devboxProjectUser, devCenterDevBoxUserRoleId)
  properties: {
    roleDefinitionId: devCenterDevBoxUserRoleId
    principalType: 'User'
    principalId: devboxProjectUser
  }
}
output projectId string = project.id

var devCenterDevBoxAdminRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '331c37c6-af14-46d9-b9f4-e1909e1b95a0')
resource projectAdminRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(!empty(devboxProjectAdmin)) {
  scope: project
  name: guid(project.id, devboxProjectAdmin, devCenterDevBoxAdminRoleId)
  properties: {
    roleDefinitionId: devCenterDevBoxAdminRoleId
    principalType: 'User'
    principalId: devboxProjectAdmin
  }
}

resource dcDiags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: devCenter.name
  scope: devCenter
  properties: {
    workspaceId: logs.id
    logs: [
      {
        enabled: true
        categoryGroup: 'allLogs'
      }
      {
        enabled: true
        categoryGroup: 'audit'
      }
    ]
  }
}

resource logs 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-${devCenterName}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

output devcenterName string = devCenter.name
