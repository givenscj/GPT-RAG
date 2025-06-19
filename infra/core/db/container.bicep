param name string
param databaseName string
param partitionKey string = '/id'
param analyticalStoreTTL int = -1
param autoscaleMaxThroughput int = 1000

resource  server 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' existing = {
  name: databaseName
  scope: resourceGroup()
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  parent: server
  name: name
  properties: {
    resource: {
      id: name
      partitionKey: {
        paths: [
          partitionKey
        ]
        kind: 'Hash'
      }
      analyticalStorageTtl: analyticalStoreTTL
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
      }
      defaultTtl: 86400
    }
    options: {
      autoscaleSettings: {
        maxThroughput: autoscaleMaxThroughput
      }
    }
  }
}

output containerId string = container.id
output containerName string = container.name
