resource virtualhub 'Microsoft.Network/virtualHubs@2022-05-01' existing = {
  name: 'wth-vhub-hub01'
}  

resource spoke1vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: 'wth-vnet-spoke101'
  scope: resourceGroup('wth-rg-spoke1')
}

resource spoke2vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: 'wth-vnet-spoke201'
  scope: resourceGroup('wth-rg-spoke2')
}

resource hubvirtualnetworkconnections1 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2022-05-01' = {
  name: 'wth-vnetcsn-spoke101'
  parent: virtualhub
  properties: {
    remoteVirtualNetwork: {
      id: spoke1vnet.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
}

resource hubvirtualnetworkconnections2 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2022-05-01' = {
  name: 'wth-vnetcxn-spoke201'
  parent: virtualhub
  properties: {
    remoteVirtualNetwork: {
      id: spoke2vnet.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
}
