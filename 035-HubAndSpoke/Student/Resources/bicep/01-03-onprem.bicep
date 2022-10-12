param location string = 'eastus2'
param onpremVMUsername string = 'admin-wth'
@secure()
param vmPassword string

targetScope = 'resourceGroup'
//onprem resources

resource wthonpremvnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: 'wth-vnet-onprem01'
}

resource wthonpremvmpip01 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'wth-pip-onpremvm01'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource wthonpremvmnic 'Microsoft.Network/networkInterfaces@2022-01-01' existing = {
  name: 'wth-nic-onpremvm01'
}

resource wthonpremvm01 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'wth-vm-onprem01'
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
        name: 'wth-disk-vmonpremos01'
        createOption: 'FromImage'
        caching: 'ReadWrite'
      }
    }
    osProfile: {
      computerName: 'vm-onprem01'
      adminUsername: onpremVMUsername
      adminPassword: vmPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: wthonpremvmnic.id
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
  name: '${wthonpremvm01.name}/wth-vmextn-changerdpport33899'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      commandToExecute: 'powershell.exe -ep bypass -encodedcommand UwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACIASABLAEwATQA6AFwAUwB5AHMAdABlAG0AXABDAHUAcgByAGUAbgB0AEMAbwBuAHQAcgBvAGwAUwBlAHQAXABDAG8AbgB0AHIAbwBsAFwAVABlAHIAbQBpAG4AYQBsACAAUwBlAHIAdgBlAHIAXABXAGkAbgBTAHQAYQB0AGkAbwBuAHMAXABSAEQAUAAtAFQAYwBwAFwAIgAgAC0ATgBhAG0AZQAgAFAAbwByAHQATgB1AG0AYgBlAHIAIAAtAFYAYQBsAHUAZQAgADMAMwA4ADkAOQANAAoATgBlAHcALQBOAGUAdABGAGkAcgBlAHcAYQBsAGwAUgB1AGwAZQAgAC0ARABpAHMAcABsAGEAeQBOAGEAbQBlACAAIgBSAEQAUAAgADMAMwA4ADkAOQAgAFQAQwBQACIAIAAtAEQAaQByAGUAYwB0AGkAbwBuACAASQBuAGIAbwB1AG4AZAAgAC0ATABvAGMAYQBsAFAAbwByAHQAIAAzADMAOAA5ADkAIAAtAFAAcgBvAHQAbwBjAG8AbAAgAFQAQwBQACAALQBBAGMAdABpAG8AbgAgAEEAbABsAG8AdwANAAoATgBlAHcALQBOAGUAdABGAGkAcgBlAHcAYQBsAGwAUgB1AGwAZQAgAC0ARABpAHMAcABsAGEAeQBOAGEAbQBlACAAIgBSAEQAUAAgADMAMwA4ADkAOQAgAFUARABQACIAIAAtAEQAaQByAGUAYwB0AGkAbwBuACAASQBuAGIAbwB1AG4AZAAgAC0ATABvAGMAYQBsAFAAbwByAHQAIAAzADMAOAA5ADkAIAAtAFAAcgBvAHQAbwBjAG8AbAAgAFUARABQACAALQBBAGMAdABpAG8AbgAgAEEAbABsAG8AdwANAAoAUgBlAHMAdABhAHIAdAAtAFMAZQByAHYAaQBjAGUAIAAtAE4AYQBtAGUAIABUAGUAcgBtAFMAZQByAHYAaQBjAGUAIAAtAEYAbwByAGMAZQANAAoADQAKAE4AZQB3AC0ATgBlAHQARgBpAHIAZQB3AGEAbABsAFIAdQBsAGUAIAAtAEQAaQBzAHAAbABhAHkATgBhAG0AZQAgACcASQBDAE0AUAB2ADQAJwAgAC0ARABpAHIAZQBjAHQAaQBvAG4AIABJAG4AYgBvAHUAbgBkACAALQBBAGMAdABpAG8AbgAgAEEAbABsAG8AdwAgAC0AUAByAG8AdABvAGMAbwBsACAAaQBjAG0AcAB2ADQAIAAtAEUAbgBhAGIAbABlAGQAIABUAHIAdQBlAA=='
    }
  }
}

resource rtonpremvms 'Microsoft.Network/routeTables@2022-01-01' existing = {
  name: 'wth-rt-onpremvmssubnet'
}

resource nsgonpremvms 'Microsoft.Network/networkSecurityGroups@2022-01-01' existing = {
  name: 'wth-nsg-onpremvmssubnet'
}

resource wthonpremcsrpip01 'Microsoft.Network/publicIPAddresses@2022-01-01' existing = {
  name: 'wth-pip-csr01'
}

resource wthonpremcsrnic 'Microsoft.Network/networkInterfaces@2022-01-01' existing = {
  name: 'wth-nic-csr01'
}

resource ciscocsr 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'wth-vm-ciscocsr01'
  location: location
  plan: {
    publisher: 'cisco'
    product: 'cisco-csr-1000v'
    name: '16_12-byol'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }
    storageProfile: {
      imageReference: {
        publisher: 'cisco'
        offer: 'cisco-csr-1000v'
        sku: '16_12-byol'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: wthonpremcsrnic.id
        }
      ]
    }
    osProfile: {
      adminUsername: onpremVMUsername
      adminPassword: vmPassword
      computerName: 'wthcsr01'
      customData: loadFileAsBase64('./csrScript.txt.tmp')
    }
  }
}
