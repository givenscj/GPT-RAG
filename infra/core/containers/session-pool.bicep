@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('MSI for resource.')
param identityId string = ''

param poolManagementType string = 'Dynamic'
param containerType string = 'PythonLTS'

resource main 'Microsoft.App/sessionPools@2025-01-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    environmentId: null
    poolManagementType: poolManagementType
    containerType: containerType
    scaleConfiguration: {
        maxConcurrentSessions: 100
    }
    dynamicPoolConfiguration: {
        lifecycleConfiguration:{

        }
    }
    sessionNetworkConfiguration: {
        status: 'EgressDisabled'
    }
  }
}
