param locationSecondary string = 'eastus2'

targetScope = 'resourceGroup'
//onprem resources


resource wthonpremcsrpip02 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'wth-pip-csr02'
  location: locationSecondary
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource wthonpremcsrnic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: 'wth-nic-csr02'
  location: locationSecondary
  properties: {
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${wthonpremvnet2.id}/subnets/subnet-vpn'
          }
          privateIPAddress: '172.17.0.4'
          publicIPAddress: {
            id: wthonpremcsrpip02.id
          }
        }
      }
    ]
  }
}

resource wthonpremvnet2 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'wth-vnet-onprem02'
  location: locationSecondary
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.17.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-vpn'
        properties: {
          addressPrefix: '172.17.0.0/24'
        }
      }
      {
        name: 'subnet-onpremvms'
        properties: {
          addressPrefix: '172.17.10.0/24'
          networkSecurityGroup: {
            id: nsgonpremvms.id
          }
          routeTable: { 
            id: rtonpremvms.id 
          }
        }
      }
    ]
  }
}

resource rtonpremvms 'Microsoft.Network/routeTables@2022-01-01' = {
  name: 'wth-rt-onpremvmssubnet'
  location: locationSecondary
  properties: {
    routes: [
      {
        name: 'route-hub'
        properties: {
          addressPrefix: '10.0.0.0/16'
          nextHopIpAddress: '172.17.0.4'
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'route-spoke1'
        properties: {
          addressPrefix: '10.1.0.0/16'
          nextHopIpAddress: '172.17.0.4'
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'route-spoke2'
        properties: {
          addressPrefix: '10.2.0.0/16'
          nextHopIpAddress: '172.17.0.4'
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'route-onprem'
        properties: {
          addressPrefix: '172.16.0.0/16'
          nextHopIpAddress: '172.16.0.4'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
    disableBgpRoutePropagation: false
  }
}

resource nsgonpremvms 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'wth-nsg-onpremvmssubnet'
  location: locationSecondary
  properties: {
    securityRules: [
      {
        name: 'allow-altrdp-to-vmssubnet-from-any'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '33899-33899'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '172.17.10.0/24'
        }
      }
      {
        name: 'allow-altssh-to-vmssubnet-from-any'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22222-22222'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '172.17.10.0/24'
        }
      }
    ]
  }
}
