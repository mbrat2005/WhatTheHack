param location string = 'eastus2'
param hubVMUsername string = 'admin-wth'
@secure()
param hubVMPassword string

targetScope = 'resourceGroup'
//hub resources

resource wthhubvnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'wth-vnet-hub01'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          routeTable: {
            id: rtvnetgw.id
          }
        }
      }
      {
        name: 'subnet-hubvms'
        properties: {
          addressPrefix: '10.0.10.0/24'
          routeTable: {
            id: rthubvms.id
          }
          networkSecurityGroup: {
            id: nsghubvms.id
          }
        }
      }
    ]
  }
}

resource wthhubgwpip01 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'wth-pip-gw01'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

resource wthhubgwpip02 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'wth-pip-gw02'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

resource wthhubvnetgw 'Microsoft.Network/virtualNetworkGateways@2022-01-01' = {
  name: 'wth-vngw-hub01'
  location: location
  properties: {
    activeActive: true
    bgpSettings: {
      asn: 65515
    }
    enableBgp: true
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation2'
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: wthhubgwpip01.id
          }
          subnet: {
            id: '${wthhubvnet.id}/subnets/GatewaySubnet'
          }
        }
      }
      {
        name: 'ipconfig2'
        properties: {
          publicIPAddress: {
            id: wthhubgwpip02.id
          }
          subnet: {
            id: '${wthhubvnet.id}/subnets/GatewaySubnet'
          }
        }
      }
    ]
  }
}

resource wthhubvmnic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: 'wth-nic-hubvm01'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${wthhubvnet.id}/subnets/subnet-hubvms'
          }
          privateIPAddress: '10.0.10.4'
        }
      }
    ]
  }
}

resource wthhubvm01 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'wth-vm-hub01'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: 'wth-disk-vmhubos01'
        createOption: 'FromImage'
        caching: 'ReadWrite'
      }
    }
    osProfile: {
      computerName: 'vm-hub01'
      adminUsername: hubVMUsername
      adminPassword: hubVMPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: wthhubvmnic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    licenseType: 'Windows_Server'
  }
}

resource rtvnetgw 'Microsoft.Network/routeTables@2022-01-01' = {
  name: 'wth-rt-hubgwsubnet'
  location: location
  properties: {
    routes: []
    disableBgpRoutePropagation: false
  }
}

resource rthubvms 'Microsoft.Network/routeTables@2022-01-01' = {
  name: 'wth-rt-hubvmssubnet'
  location: location
  properties: {
    routes: []
    disableBgpRoutePropagation: false
  }
}

resource nsghubvms 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'wth-nsg-hubvmssubnet'
  location: location
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
          destinationAddressPrefix: '10.0.10.0/24'
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
          destinationAddressPrefix: '10.0.10.0/24'
        }
      }
    ]
  }
}
