param location string = 'eastus2'
param spoke3VMUsername string = 'admin-wth'
@secure()
param vmPassword string

targetScope = 'resourceGroup'
//spoke3 resources

resource wthspoke3vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'wth-vnet-spoke301'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.3.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-spoke3vms'
        properties: {
          addressPrefix: '10.3.10.0/24'
        }
      }
    ]
  }
}

resource wthspoke3vmpip01 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'wth-pip-spoke3vm01'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource wthspoke3vmnic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: 'wth-nic-spoke3vm01'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${wthspoke3vnet.id}/subnets/subnet-spoke3vms'
          }
          privateIPAddress: '10.3.10.4'
          publicIPAddress: {
            id: wthspoke3vmpip01.id
          }
        }
      }
    ]
  }
}

resource wthspoke3vm01 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'wth-vm-spoke301'
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
        name: 'wth-disk-vmspoke3os01'
        createOption: 'FromImage'
        caching: 'ReadWrite'
      }
    }
    osProfile: {
      computerName: 'vm-spoke301'
      adminUsername: spoke3VMUsername
      adminPassword: vmPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: wthspoke3vmnic.id
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
  name: '${wthspoke3vm01.name}/wth-vmextn-changerdpport33899'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      commandToExecute: 'powershell.exe -ep bypass -encodedcommand UwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACIASABLAEwATQA6AFwAUwB5AHMAdABlAG0AXABDAHUAcgByAGUAbgB0AEMAbwBuAHQAcgBvAGwAUwBlAHQAXABDAG8AbgB0AHIAbwBsAFwAVABlAHIAbQBpAG4AYQBsACAAUwBlAHIAdgBlAHIAXABXAGkAbgBTAHQAYQB0AGkAbwBuAHMAXABSAEQAUAAtAFQAYwBwAFwAIgAgAC0ATgBhAG0AZQAgAFAAbwByAHQATgB1AG0AYgBlAHIAIAAtAFYAYQBsAHUAZQAgADMAMwA4ADkAOQAKAE4AZQB3AC0ATgBlAHQARgBpAHIAZQB3AGEAbABsAFIAdQBsAGUAIAAtAEQAaQBzAHAAbABhAHkATgBhAG0AZQAgACIAUgBEAFAAIAAzADMAOAA5ADkAIABUAEMAUAAiACAALQBEAGkAcgBlAGMAdABpAG8AbgAgAEkAbgBiAG8AdQBuAGQAIAAtAEwAbwBjAGEAbABQAG8AcgB0ACAAMwAzADgAOQA5ACAALQBQAHIAbwB0AG8AYwBvAGwAIABUAEMAUAAgAC0AQQBjAHQAaQBvAG4AIABBAGwAbABvAHcACgBOAGUAdwAtAE4AZQB0AEYAaQByAGUAdwBhAGwAbABSAHUAbABlACAALQBEAGkAcwBwAGwAYQB5AE4AYQBtAGUAIAAiAFIARABQACAAMwAzADgAOQA5ACAAVQBEAFAAIgAgAC0ARABpAHIAZQBjAHQAaQBvAG4AIABJAG4AYgBvAHUAbgBkACAALQBMAG8AYwBhAGwAUABvAHIAdAAgADMAMwA4ADkAOQAgAC0AUAByAG8AdABvAGMAbwBsACAAVQBEAFAAIAAtAEEAYwB0AGkAbwBuACAAQQBsAGwAbwB3AAoAUgBlAHMAdABhAHIAdAAtAFMAZQByAHYAaQBjAGUAIAAtAE4AYQBtAGUAIABUAGUAcgBtAFMAZQByAHYAaQBjAGUAIAAtAEYAbwByAGMAZQA='
    }
  }
}

resource rtspoke3vms 'Microsoft.Network/routeTables@2022-01-01' = {
  name: 'wth-rt-spoke3vmssubnet'
  location: location
  properties: {
    routes: []
    disableBgpRoutePropagation: true
  }
}

resource nsgspoke1vms 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'wth-nsg-spoke3vmssubnet'
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
          destinationAddressPrefix: '10.3.10.0/24'
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
          destinationAddressPrefix: '10.3.10.0/24'
        }
      }
    ]
  }
}
