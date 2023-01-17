param site_name string = 'edvangetest'
param site_storage_name string = 'edvangeweb'
param serverfarms_name string = 'ASP-edvangetest'
param appinsights_name string = 'edvangetestappins'
param appinsights_workspace_name string = 'workspace-edvangetestappins'
param data_storage_name string = 'edvangestorage'
param location string = 'westeurope'

resource data_storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: data_storage_name
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    isSftpEnabled: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    isHnsEnabled: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource site_storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: site_storage_name
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'Storage'
  properties: {
    minimumTlsVersion: 'TLS1_0'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

resource data_storage_blob_service_default 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  parent: data_storage
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
  }
}

resource site_storage_blob_service_default 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  parent: site_storage
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource data_storage_file_service_default 'Microsoft.Storage/storageAccounts/fileServices@2022-05-01' = {
  parent: data_storage
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource site_storage_file_service_default 'Microsoft.Storage/storageAccounts/fileServices@2022-05-01' = {
  parent: site_storage
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource data_storage_queue_default 'Microsoft.Storage/storageAccounts/queueServices@2022-05-01' = {
  parent: data_storage
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource site_storage_queue_default 'Microsoft.Storage/storageAccounts/queueServices@2022-05-01' = {
  parent: site_storage
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource data_storage_web 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  parent: data_storage_blob_service_default
  name: '$web'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource data_storage_data_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  parent: data_storage_blob_service_default
  name: 'data'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource data_storage_output_container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  parent: data_storage_blob_service_default
  name: 'output'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource data_storage_config_files 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-05-01' = {
  parent: data_storage_file_service_default
  name: 'config'
  properties: {
    accessTier: 'Hot'
    shareQuota: 5120
    enabledProtocols: 'SMB'
  }
}

resource appinsights_workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: appinsights_workspace_name
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource app_service_plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: serverfarms_name
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  kind: 'functionapp'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

resource appinsights 'microsoft.insights/components@2020-02-02' = {
  name: appinsights_name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 90
    WorkspaceResourceId: appinsights_workspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}
resource site 'Microsoft.Web/sites@2022-03-01' = {
  name: site_name
  location: location
  kind: 'functionapp,linux'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${site_name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${site_name}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: app_service_plan.id
    reserved: true
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'PYTHON|3.9'
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 200
      minimumElasticInstanceCount: 0
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appinsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsFeatureFlags'
          value: 'EnableWorkerIndexing'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${site_storage_name};AccountKey=${listKeys(site_storage.id, site_storage.apiVersion).keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'DATA_DOC_STORAGE'
          value: 'DefaultEndpointsProtocol=https;AccountName=${data_storage_name};AccountKey=${listKeys(data_storage.id, data_storage.apiVersion).keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'DATA_STORAGE'
          value: 'DefaultEndpointsProtocol=https;AccountName=${data_storage_name};AccountKey=${listKeys(data_storage.id, data_storage.apiVersion).keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'ROOT_FOLDER_PATH'
          value: '/gx_config/great_expectations'
        }
      ]
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: false
    redundancyMode: 'None'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource site_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-03-01' = {
  parent: site
  name: 'ftp'
  location: location
  properties: {
    allow: true
  }
}

resource site_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-03-01' = {
  parent: site
  name: 'scm'
  location: location
  properties: {
    allow: true
  }
}

resource site_web 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: site
  name: 'web'
  location: location
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
    ]
    netFrameworkVersion: 'v4.0'
    linuxFxVersion: 'PYTHON|3.9'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    remoteDebuggingVersion: 'VS2019'
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$edvangetest'
    scmType: 'None'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: false
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 0
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'AllAllowed'
    preWarmedInstanceCount: 0
    functionAppScaleLimit: 200
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {
      'config-share': {
        type: 'AzureFiles'
        accountName: data_storage_name
        shareName: 'config'
        mountPath: '/gx_config'
        accessKey: '${listKeys(data_storage.id, data_storage.apiVersion).keys[0].value}'
      }
    }
  }
  dependsOn: [
    data_storage_config_files
  ]
}

resource site_binding 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  parent: site
  name: '${site_name}.azurewebsites.net'
  location: location
  properties: {
    siteName: site_name
    hostNameType: 'Verified'
  }
}
