param location string = 'eastus2'

resource wthafw 'Microsoft.Network/azureFirewalls@2022-01-01' existing = {
  name: 'wth-afw-hub01'
  scope: resourceGroup('wth-rg-hub')
}

