param location string = 'eastus2'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: 'wth-law-default01'
  scope: resourceGroup('wth-rg-hub')
}

resource flowLogStorage 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: 'wthflow${uniqueString(subscription().subscriptionId, 'wth-rg-hub')}'
  scope: resourceGroup('wth-rg-hub')
}

resource networkwatcher 'Microsoft.Network/networkWatchers@2019-11-01' existing = {
  name: 'NetworkWatcher_${location}'
  scope: resourceGroup('NetworkWatcherRG')
} 

resource nsgspoke1vms 'Microsoft.Network/networkSecurityGroups@2022-01-01' existing = {
  name: 'wth-nsg-spoke1vmssubnet'
  scope: resourceGroup('wth-rg-spoke1')
}

resource nsgspoke1vmsflowlgos 'Microsoft.Network/networkWatchers/flowLogs@2022-01-01' = {
  name: '${networkwatcher.name}/wth-nsg-spoke1vmssubnet-flowlog'
  location: location
  properties: {
    storageId: flowLogStorage.id
    targetResourceId: nsgspoke1vms.id
    enabled: true
    format: {
      type: 'JSON'
    }
    retentionPolicy: {
      days: 7
      enabled: true
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: logAnalytics.id
      }
    }
  }
}

resource nsgspoke2vms 'Microsoft.Network/networkSecurityGroups@2022-01-01' existing = {
  name: 'wth-nsg-spoke2vmssubnet'
  scope: resourceGroup('wth-rg-spoke2')
}

resource nsgspoke2vmsflowlgos 'Microsoft.Network/networkWatchers/flowLogs@2022-01-01' = {
  name: '${networkwatcher.name}/wth-nsg-spoke2vmssubnet-flowlog'
  location: location
  properties: {
    storageId: flowLogStorage.id
    targetResourceId: nsgspoke2vms.id
    enabled: true
    format: {
      type: 'JSON'
    }
    retentionPolicy: {
      days: 7
      enabled: true
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: logAnalytics.id
      }
    }
  }
}

resource nsgspoke3vms 'Microsoft.Network/networkSecurityGroups@2022-01-01' existing = {
  name: 'wth-nsg-spoke3vmssubnet'
  scope: resourceGroup('wth-rg-spoke3')
}

resource nsgspoke3vmsflowlgos 'Microsoft.Network/networkWatchers/flowLogs@2022-01-01' = {
  name: '${networkwatcher.name}/wth-nsg-spoke3vmssubnet-flowlog'
  location: location
  properties: {
    storageId: flowLogStorage.id
    targetResourceId: nsgspoke3vms.id
    enabled: true
    format: {
      type: 'JSON'
    }
    retentionPolicy: {
      days: 7
      enabled: true
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: logAnalytics.id
      }
    }
  }
}

resource nsghubvms 'Microsoft.Network/networkSecurityGroups@2022-01-01' existing = {
  name: 'wth-nsg-hubvmssubnet'
  scope: resourceGroup('wth-rg-hub')
}

resource nsghubvmsflowlgos 'Microsoft.Network/networkWatchers/flowLogs@2022-01-01' = {
  name: '${networkwatcher.name}/wth-nsg-hubvmssubnet-flowlog'
  location: location
  properties: {
    storageId: flowLogStorage.id
    targetResourceId: nsghubvms.id
    enabled: true
    format: {
      type: 'JSON'
    }
    retentionPolicy: {
      days: 7
      enabled: true
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: logAnalytics.id
      }
    }
  }
}
