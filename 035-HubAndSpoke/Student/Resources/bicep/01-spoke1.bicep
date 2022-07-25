param location string = 'eastus2'
param spoke1VMUsername string = 'admin-wth'
@secure()
param spoke1VMPassword string

targetScope = 'resourceGroup'
//spoke1 resources

resource wthspoke1vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'wth-vnet-spoke101'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-spoke1vms'
        properties: {
          addressPrefix: '10.1.10.0/24'
          networkSecurityGroup: {id: nsgspoke1vms.id}
          routeTable: { id: rtspoke1vms.id }
        }
      }
    ]
  }
}

resource wthspoke1vmpip01 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'wth-pip-spoke1vm01'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource wthspoke1vmnic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: 'wth-nic-spoke1vm01'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${wthspoke1vnet.id}/subnets/subnet-spoke1vms'
          }
          privateIPAddress: '10.1.10.4'
          publicIPAddress: {
            id: wthspoke1vmpip01.id
          }
        }
      }
    ]
  }
}

resource wthspoke1vm01 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'wth-vm-spoke101'
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
        name: 'wth-disk-vmspoke1os01'
        createOption: 'FromImage'
        caching: 'ReadWrite'
      }
    }
    osProfile: {
      computerName: 'vm-spoke101'
      adminUsername: spoke1VMUsername
      adminPassword: spoke1VMPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: wthspoke1vmnic.id
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

resource changerdpport 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  name: '${wthspoke1vm01.name}/wth-vmextn-changerdpport'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      commandToExecute: 'powershell.exe -ep bypass -encodedcommand U2V0LUl0ZW1Qcm9wZXJ0eSAtUGF0aCAiSEtMTTpcU3lzdGVtXEN1cnJlbnRDb250cm9sU2V0XENvbnRyb2xcVGVybWluYWwgU2VydmVyXFdpblN0YXRpb25zXFJEUC1UY3BcIiAtTmFtZSBQb3J0TnVtYmVyIC1WYWx1ZSAzMzg5OQpOZXctTmV0RmlyZXdhbGxSdWxlIC1EaXNwbGF5TmFtZSAiUkRQIDMzODk5IFRDUCIgLURpcmVjdGlvbiBJbmJvdW5kIC1Mb2NhbFBvcnQgNTAxMDIgLVByb3RvY29sIFRDUCAtQWN0aW9uIEFsbG93Ck5ldy1OZXRGaXJld2FsbFJ1bGUgLURpc3BsYXlOYW1lICJSRFAgMzM4OTkgVURQIiAtRGlyZWN0aW9uIEluYm91bmQgLUxvY2FsUG9ydCA1MDEwMiAtUHJvdG9jb2wgVURQIC1BY3Rpb24gQWxsb3cKUmVzdGFydC1TZXJ2aWNlIC1OYW1lIFRlcm1TZXJ2aWNlIC1Gb3JjZQ=='
    }
  }
}

resource rtspoke1vms 'Microsoft.Network/routeTables@2022-01-01' = {
  name: 'wth-rt-spoke1vmssubnet'
  location: location
  properties: {
    routes: []
    disableBgpRoutePropagation: false
  }
}

resource nsgspoke1vms 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'wth-nsg-spoke1vmssubnet'
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
          destinationAddressPrefix: '10.1.10.0/24'
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
          destinationAddressPrefix: '10.1.10.0/24'
        }
      }
    ]
  }
}
