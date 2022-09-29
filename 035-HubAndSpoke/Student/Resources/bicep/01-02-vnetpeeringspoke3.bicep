resource hubvnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: 'wth-vnet-hub01'
  scope: resourceGroup('wth-rg-hub')
}

resource spoke3vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: 'wth-vnet-spoke301'
  scope: resourceGroup('wth-rg-spoke3')
}

resource spoke3tohub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  name: '${spoke3vnet.name}/wth-peering-spoke1tohub'
  properties: {
    allowGatewayTransit: false
    allowForwardedTraffic: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: hubvnet.id
    }
  }
}
