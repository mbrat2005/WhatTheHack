param location string = 'eastus2'
param locationSecondary string = 'westus3'
param hubVMUsername string = 'admin-wth'
@secure()
param vmPassword string

targetScope = 'resourceGroup'

resource wthcsrpip01 'Microsoft.Network/publicIPAddresses@2022-01-01' existing = {
  name: 'wth-pip-csr01'
  scope: resourceGroup('wth-rg-onprem') 
}

resource wthcsrnic 'Microsoft.Network/networkInterfaces@2022-01-01' existing = {
  name: 'wth-nic-csr01'
  scope: resourceGroup('wth-rg-onprem')
}

resource wthcsrpip02 'Microsoft.Network/publicIPAddresses@2022-01-01' existing = {
  name: 'wth-pip-csr02'
  scope: resourceGroup('wth-rg-onprem2') 
}

resource wthcsrnic2 'Microsoft.Network/networkInterfaces@2022-01-01' existing = {
  name: 'wth-nic-csr02'
  scope: resourceGroup('wth-rg-onprem2')
}
//hub resources


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
  name: 'wth-vhub-hub${location}01'
  location: location
  properties: {
    virtualWan: {
      id: virtualwans.id
    }
    addressPrefix: '10.0.0.0/16'
  }
}

resource virtualhub2 'Microsoft.Network/virtualHubs@2022-05-01' = {
  name: 'wth-vhub-hub${locationSecondary}01'
  location: locationSecondary
  properties: {
    virtualWan: {
      id: virtualwans.id
    }
    addressPrefix: '10.10.0.0/16'
  }
}

resource vpnsites 'Microsoft.Network/vpnSites@2022-05-01' = {
  name: 'wth-vpnsite-hub${location}01'
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
      bgpPeeringAddress: wthcsrnic.properties.ipConfigurations[0].properties.privateIPAddress
    }
    ipAddress: wthcsrpip01.properties.ipAddress
  }
}

resource vpnsites2 'Microsoft.Network/vpnSites@2022-05-01' = {
  name: 'wth-vpnsite-hub${locationSecondary}01'
  location: locationSecondary
  properties: {
    virtualWan: {
      id: virtualwans.id
    }
    addressSpace: {
      addressPrefixes: [
        '172.17.0.0/16'
      ]
    }
    bgpProperties: {
      asn: 65511
      bgpPeeringAddress: wthcsrnic2.properties.ipConfigurations[0].properties.privateIPAddress
    }
    ipAddress: wthcsrpip02.properties.ipAddress
  }
}

resource vpngateways 'Microsoft.Network/vpnGateways@2022-05-01' = {
  name: 'wth-vngw-hub${location}01'
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
          sharedKey: '123mysecretkey'

        }
      }
    ]
  }
}

resource vpngateways2 'Microsoft.Network/vpnGateways@2022-05-01' = {
  name: 'wth-vngw-hub${locationSecondary}01'
  location: locationSecondary
  properties: {
    bgpSettings: {
      asn: 65515
    }
    virtualHub: {
      id: virtualhub2.id
    }
    connections: [
      {
        name: 'wth-cxn-hub01'
        properties: {
          enableBgp: true
          connectionBandwidth: 1
          remoteVpnSite: {
            id: vpnsites2.id
          }
          sharedKey: '123mysecretkey'

        }
      }
    ]
  }
}

output vpngatewaysasn int = vpngateways.properties.bgpSettings.asn
output vpngatewaysprivateip1 string = vpngateways.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[1]
output vpngatewaysprivateip2 string = vpngateways.properties.bgpSettings.bgpPeeringAddresses[1].tunnelIpAddresses[1]
output pipgw1 string = vpngateways.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]
output pipgw2 string = vpngateways.properties.bgpSettings.bgpPeeringAddresses[1].tunnelIpAddresses[0]
output wthhubvnetgwBGPip1 string = vpngateways.properties.bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]
output wthhubvnetgwBGPip2 string = vpngateways.properties.bgpSettings.bgpPeeringAddresses[1].defaultBgpIpAddresses[0]

output vpngatewaysasn2 int = vpngateways2.properties.bgpSettings.asn
output vpngatewaysprivateip12 string = vpngateways2.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[1]
output vpngatewaysprivateip22 string = vpngateways2.properties.bgpSettings.bgpPeeringAddresses[1].tunnelIpAddresses[1]
output pipgw12 string = vpngateways2.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]
output pipgw22 string = vpngateways2.properties.bgpSettings.bgpPeeringAddresses[1].tunnelIpAddresses[0]
output wthhubvnetgwBGPip12 string = vpngateways2.properties.bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]
output wthhubvnetgwBGPip22 string = vpngateways2.properties.bgpSettings.bgpPeeringAddresses[1].defaultBgpIpAddresses[0]

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
