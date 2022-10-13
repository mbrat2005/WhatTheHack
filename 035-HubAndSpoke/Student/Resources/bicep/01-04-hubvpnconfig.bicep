param locationSecondary string = 'eastus2'

resource onpremcsrpip 'Microsoft.Network/publicIPAddresses@2022-01-01' existing = {
  name: 'wth-pip-csr02'
  scope: resourceGroup('wth-rg-onprem')
}

resource onpremcsrnic 'Microsoft.Network/networkInterfaces@2022-01-01' existing = {
  name: 'wth-nic-csr02'
  scope: resourceGroup('wth-rg-onprem')
}

resource wthhublocalgw 'Microsoft.Network/localNetworkGateways@2022-01-01' = {
  name: 'wth-lgw-onprem01'
  location: locationSecondary
  properties: {
    gatewayIpAddress: onpremcsrpip.properties.ipAddress
    localNetworkAddressSpace: {
      addressPrefixes: [
        '172.17.0.0/16'
      ]
    }
    bgpSettings: {
      bgpPeeringAddress: onpremcsrnic.properties.ipConfigurations[0].properties.privateIPAddress
      asn: 65510
    }
  }
}
