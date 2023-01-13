targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //
@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(90)
param resourceGroupName string = 'ms.synapse.workspaces-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'swenua'

@description('Generated. Used as a basis for unique resource names.')
param baseTime string = utcNow('u')

// ============ //
// Dependencies //
// ============ //

// General resources
// =================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module nestedDependencies 'dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-nestedDependencies'
  params: {
    // Adding base time to make the name unique as purge protection must be enabled (but may not be longer than 24 characters total)
    keyVaultName: 'dep-<<namePrefix>>-kv-${serviceShort}-${substring(uniqueString(baseTime), 0, 3)}'
    managedIdentityName: 'dep-<<namePrefix>>-msi-${serviceShort}'
    storageAccountName: 'dep<<namePrefix>>sa${serviceShort}01'
  }
}

// ============== //
// Test Execution //
// ============== //

module testDeployment '../../deploy.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name)}-test-${serviceShort}'
  params: {
    name: '<<namePrefix>>${serviceShort}001'
    defaultDataLakeStorageAccountName: nestedDependencies.outputs.storageAccountName
    defaultDataLakeStorageFilesystem: nestedDependencies.outputs.storageContainerName
    sqlAdministratorLogin: 'synwsadmin'
    encryption: true
    cMKKeyVaultResourceId: nestedDependencies.outputs.keyVaultResourceId
    cMKKeyName: nestedDependencies.outputs.keyVaultEncryptionKeyName
    cMKUserAssignedIdentityResourceId: nestedDependencies.outputs.managedIdentityResourceId
  }
}
}
