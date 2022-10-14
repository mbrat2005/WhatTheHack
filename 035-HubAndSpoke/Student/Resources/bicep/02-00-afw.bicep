param location string = 'eastus2'

resource virtualhub 'Microsoft.Network/virtualHubs@2022-05-01' existing = {
  name: 'wth-vhub-hub${location}01'
}

resource wthafwpip01 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'wth-pip-afw01'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource wthafwpolicy 'Microsoft.Network/firewallPolicies@2022-01-01' = {
  name: 'wth-fwp-standard01'
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
  }
}

resource wthafw 'Microsoft.Network/azureFirewalls@2022-01-01' = {
  name: 'wth-afw-hub01'
  location: location
  properties: {
    sku: {
      name: 'AZFW_Hub'
      tier: 'Standard'
    }
    virtualHub: {
      id: virtualhub.id
    }
    firewallPolicy: {
      id: wthafwpolicy.id
    }
    hubIPAddresses: {
      publicIPs: {
        count: 2 
      }
    }
  }
}

resource wthlaw 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: 'wth-law-default01'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource wthafwdiagsettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagSettingsAFW'
  scope: wthafw
  properties: {
    workspaceId: wthlaw.id
    logs: [
      {
        enabled: true
        categoryGroup: 'allLogs'
        retentionPolicy: {
          enabled: true
          days: 14
        }
      }
    ]
    logAnalyticsDestinationType: 'Dedicated'
  }
}

