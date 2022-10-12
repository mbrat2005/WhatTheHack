param location string = 'eastus2'
param hubVMUsername string = 'admin-wth'
@secure()
param vmPassword string

targetScope = 'resourceGroup'

resource wthonpremvmpip01 'Microsoft.Network/publicIPAddresses@2022-01-01' existing = {
  name: 'wth-pip-onpremvm01'
  scope: resourceGroup('wth-rg-onprem') 
}

resource wthonpremvmnic 'Microsoft.Network/networkInterfaces@2022-01-01' existing = {
  name: 'wth-nic-onpremvm01'
  scope: resourceGroup('wth-rg-onprem')
}
//hub resources

/* resource wthhubvnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
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
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
} */

resource virtualwans 'Microsoft.Network/virtualWans@2022-05-01' = {
  name: 'wth-vwan-hub02'
  location: location
  properties: {
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: true
    type: 'Standard'
  }
}

resource virtualhub 'Microsoft.Network/virtualHubs@2022-05-01' = {
  name: 'wth-vhub-hub02'
  location: location
  properties: {
    virtualWan: {
      id: virtualwans.id
    }
    addressPrefix: '10.0.0.0/16'
  }
}

resource vpnsites 'Microsoft.Network/vpnSites@2022-05-01' = {
  name: 'wth-vpnsite-hub02'
  location: location
  properties: {
    virtualWan: {
      id: virtualwans.id
    }
    addressSpace: {
      addressPrefixes: [
        '172.16.0.0/16'
      ]
    }
    bgpProperties: {
      asn: 65510
      bgpPeeringAddress: wthonpremvmnic.properties.ipConfigurations[0].properties.privateIPAddress
    }
    ipAddress: wthonpremvmpip01.properties.ipAddress
  }
}

resource wthhubgwpip01 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'wth-pip-gw01'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}
output pipgw1 string = wthhubgwpip01.properties.ipAddress


resource wthhubgwpip02 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'wth-pip-gw02'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

output pipgw2 string = wthhubgwpip02.properties.ipAddress

resource vpngateways 'Microsoft.Network/vpnGateways@2021-03-01' = {
  name: 'wth-vngw-hub02'
  location: location
  properties: {
    bgpSettings: {
      asn: 65515
    }
    virtualHub: {
      id: virtualhub.id
    }
    connections: [
      {
        name: 'wth-cxn-hub01'
        properties: {
          enableBgp: true
          connectionBandwidth: 1
          remoteVpnSite: {
            id: vpnsites.id
          }
        }
      }
    ]
  }
}

output vpngatewaysasn int = vpngateways.properties.bgpSettings.asn
output vpngatewaysprivateip1 string = vpngateways.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]
output vpngatewaysprivateip2 string = vpngateways.properties.bgpSettings.bgpPeeringAddresses[1].tunnelIpAddresses[0]
output wthhubvnetgwprivateip1 string = vpngateways.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[1]
output wthhubvnetgwprivateip2 string = vpngateways.properties.bgpSettings.bgpPeeringAddresses[1].tunnelIpAddresses[1]

/*
resource changerdpport 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  name: '${wthhubvm01.name}/wth-vmextn-changerdpport33899'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      /*
      To generate encoded command in PowerShell: 

      $s = @'
      Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\" -Name PortNumber -Value 33899
      New-NetFirewallRule -DisplayName "RDP 33899 TCP" -Direction Inbound -LocalPort 33899 -Protocol TCP -Action Allow
      New-NetFirewallRule -DisplayName "RDP 33899 UDP" -Direction Inbound -LocalPort 33899 -Protocol UDP -Action Allow
      Restart-Service -Name TermService -Force

      New-NetFirewallRule -DisplayName 'ICMPv4' -Direction Inbound -Action Allow -Protocol icmpv4 -Enabled True
      '@
      $bytes = [System.Text.Encoding]::Unicode.GetBytes($s)
      [convert]::ToBase64String($bytes) 
      commandToExecute: 'powershell.exe -ep bypass -encodedcommand UwBlAHQALQBJAHQAZQBtAFAAcgBvAHAAZQByAHQAeQAgAC0AUABhAHQAaAAgACIASABLAEwATQA6AFwAUwB5AHMAdABlAG0AXABDAHUAcgByAGUAbgB0AEMAbwBuAHQAcgBvAGwAUwBlAHQAXABDAG8AbgB0AHIAbwBsAFwAVABlAHIAbQBpAG4AYQBsACAAUwBlAHIAdgBlAHIAXABXAGkAbgBTAHQAYQB0AGkAbwBuAHMAXABSAEQAUAAtAFQAYwBwAFwAIgAgAC0ATgBhAG0AZQAgAFAAbwByAHQATgB1AG0AYgBlAHIAIAAtAFYAYQBsAHUAZQAgADMAMwA4ADkAOQANAAoATgBlAHcALQBOAGUAdABGAGkAcgBlAHcAYQBsAGwAUgB1AGwAZQAgAC0ARABpAHMAcABsAGEAeQBOAGEAbQBlACAAIgBSAEQAUAAgADMAMwA4ADkAOQAgAFQAQwBQACIAIAAtAEQAaQByAGUAYwB0AGkAbwBuACAASQBuAGIAbwB1AG4AZAAgAC0ATABvAGMAYQBsAFAAbwByAHQAIAAzADMAOAA5ADkAIAAtAFAAcgBvAHQAbwBjAG8AbAAgAFQAQwBQACAALQBBAGMAdABpAG8AbgAgAEEAbABsAG8AdwANAAoATgBlAHcALQBOAGUAdABGAGkAcgBlAHcAYQBsAGwAUgB1AGwAZQAgAC0ARABpAHMAcABsAGEAeQBOAGEAbQBlACAAIgBSAEQAUAAgADMAMwA4ADkAOQAgAFUARABQACIAIAAtAEQAaQByAGUAYwB0AGkAbwBuACAASQBuAGIAbwB1AG4AZAAgAC0ATABvAGMAYQBsAFAAbwByAHQAIAAzADMAOAA5ADkAIAAtAFAAcgBvAHQAbwBjAG8AbAAgAFUARABQACAALQBBAGMAdABpAG8AbgAgAEEAbABsAG8AdwANAAoAUgBlAHMAdABhAHIAdAAtAFMAZQByAHYAaQBjAGUAIAAtAE4AYQBtAGUAIABUAGUAcgBtAFMAZQByAHYAaQBjAGUAIAAtAEYAbwByAGMAZQANAAoADQAKAE4AZQB3AC0ATgBlAHQARgBpAHIAZQB3AGEAbABsAFIAdQBsAGUAIAAtAEQAaQBzAHAAbABhAHkATgBhAG0AZQAgACcASQBDAE0AUAB2ADQAJwAgAC0ARABpAHIAZQBjAHQAaQBvAG4AIABJAG4AYgBvAHUAbgBkACAALQBBAGMAdABpAG8AbgAgAEEAbABsAG8AdwAgAC0AUAByAG8AdABvAGMAbwBsACAAaQBjAG0AcAB2ADQAIAAtAEUAbgBhAGIAbABlAGQAIABUAHIAdQBlAA=='
    }
  }
}

resource wthhubvmpip01 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'wth-pip-hubvm01'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
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
          publicIPAddress: {
            id: wthhubvmpip01.id
          }
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
      adminPassword: vmPassword
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
*/
