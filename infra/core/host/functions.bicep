param networkIsolation bool
param vnetName string
param subnetId string
param runtimeName string
param runtimeVersion string
var runtimeNameAndVersion = '${runtimeName}|${runtimeVersion}'
param alwaysOn bool = true
param appCommandLine string = ''
param numberOfWorkers int = -1
param minimumElasticInstanceCount int = -1
param use32BitWorkerProcess bool = false
param functionAppScaleLimit int = -1
param healthCheckPath string = ''
param allowedOrigins array = []

param name string
param functionAppReuse bool
param functionAppResourceGroupName string
param location string = resourceGroup().location
param tags object = {}
param keyVaultResourceGroupName string
param keyVaultName string = ''

// Reference Properties
param applicationInsightsName string = ''
param applicationInsightsResourceGroupName string

param appServicePlanId string

param storageAccountName string
param storageResourceGroupName string

param clientAffinityEnabled bool = false
@allowed(['SystemAssigned', 'UserAssigned'])
param identityType string
// @description('User assigned identity name')
// param identityId string

// Runtime Properties
param kind string = 'functionapp,linux'

// Microsoft.Web/sites/config
param appSettings array = []

resource stg 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  scope: resourceGroup(storageResourceGroupName)  
  name: storageAccountName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!(empty(keyVaultName))) {
  scope: resourceGroup(keyVaultResourceGroupName)
  name: keyVaultName
 }

 resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!empty(applicationInsightsName)) {
  scope: resourceGroup(applicationInsightsResourceGroupName)
  name: applicationInsightsName
}

 resource existingFunction 'Microsoft.Web/sites@2022-09-01' existing = if (functionAppReuse) {
  scope: resourceGroup(functionAppResourceGroupName)
  name: name
}

/** Resources **/
@description('User Assigned Identity for function')
resource uaiFunc 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  location: location
  name: 'uai-${name}'
  tags: {
    'azd-env-name' : environment().name
  }
}

resource newFunction 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  tags: tags
  kind: kind

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uaiFunc.id}': {}
    }
  }

  properties: {
    serverFarmId: appServicePlanId
    clientAffinityEnabled: clientAffinityEnabled
    virtualNetworkSubnetId: networkIsolation ? subnetId : null
    httpsOnly: true
    siteConfig: {
      vnetName: networkIsolation ? vnetName : null
      linuxFxVersion: runtimeNameAndVersion
      alwaysOn: alwaysOn
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      appCommandLine: appCommandLine
      numberOfWorkers: numberOfWorkers
      minimumElasticInstanceCount: minimumElasticInstanceCount
      use32BitWorkerProcess: use32BitWorkerProcess      
      functionAppScaleLimit: functionAppScaleLimit
      healthCheckPath: healthCheckPath
      appSettings: union(
        appSettings,
        [
          {
            name: 'AzureWebJobsStorage__clientId'
            value: uaiFunc.properties.clientId
          }
          {
            name: 'AZURE_CLIENT_ID'
            value: uaiFunc.properties.clientId
          }
          {
            name: 'AZURE_STORAGE_QUEUES_CONNECTION_STRING__clientId'
            value: uaiFunc.properties.clientId
          }
          {
            name: 'AzureWebJobsStorage__cliendId'
            value: uaiFunc.properties.clientId
          }
          {
            name: 'AZURE_KEY_VAULT_ENDPOINT'
            value: keyVault.properties.vaultUri
          }
        ]
      )
      cors: {
          allowedOrigins: union([ 'https://portal.azure.com', 'https://ms.portal.azure.com' ], allowedOrigins)
        }          

    } 
  }
}

output id string = functionAppReuse ? existingFunction.id : newFunction.id
output name string = functionAppReuse ? existingFunction.name : newFunction.name
output uri string = functionAppReuse ? 'https://${existingFunction.properties.defaultHostName}' : 'https://${newFunction.properties.defaultHostName}'
output identityPrincipalId string = uaiFunc.properties.principalId
output location string = functionAppReuse ? existingFunction.location : newFunction.location
//output functionKey string = listKeys(newFunction.id, '2016-08-01').functionKeys.default
