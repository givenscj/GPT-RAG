param name string
param location string
param tags object = {}
param subnets array
param vnetReuse bool = false
param addressPrefixes array = ['10.0.0.0/24','10.0.1.0/24']
param resourceGroupName string = resourceGroup().name

// Virtual Network and Subnets
resource existingVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = if (vnetReuse) {
  scope: resourceGroup(resourceGroupName)
  name: name
}

resource newVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = if (!vnetReuse) {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: subnets
  }
}

resource allSubnets 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = [for subnet in subnets: {
  name: subnet.name
  parent: newVnet
}]

output name string = vnetReuse ? existingVnet.name : newVnet.name
output id string = vnetReuse ? existingVnet.id : newVnet.id
output subnets array = [for (subnet, i) in subnets: {
  addressPrefix: allSubnets[i].properties.addressPrefix
  id: allSubnets[i].id
  name: allSubnets[i].name
}]

