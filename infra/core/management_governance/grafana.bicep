@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

param identityId string

resource grafana 'Microsoft.Dashboard/grafana@2024-10-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    zoneRedundancy: 'Disabled'
    publicNetworkAccess: 'Enabled'
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
    apiKey: 'Disabled'
    deterministicOutboundIP: 'Disabled'
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: []
    }
    sku: {
      name: 'Standard'
    }
    grafanaConfigurations: {
      smtp : {enabled: false}
    }
    grafanaMajorVersion: '11'
  }
}
