resource wthafwpolicy 'Microsoft.Network/firewallPolicies@2022-01-01' existing = {
  name: 'wth-fwp-standard01'
  scope: resourceGroup('wth-rg-hub')
}

resource wthspoke1vmnic 'Microsoft.Network/networkInterfaces@2022-01-01' existing = {
  name: 'wth-nic-spoke1vm01'
  scope: resourceGroup('wth-rg-spoke1')
}

resource wthspoke2vmnic 'Microsoft.Network/networkInterfaces@2022-01-01' existing = {
  name: 'wth-nic-spoke2vm01'
  scope: resourceGroup('wth-rg-spoke2')
}

resource wthafw 'Microsoft.Network/azureFirewalls@2022-01-01' existing = {
  name: 'wth-afw-hub01'
}

resource wthafwrcgdnat 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  name: '${wthafwpolicy.name}/WTH_DNATRulesCollectionGroup'
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        action: {
          type: 'DNAT'
        }
        name: 'dnat-webservers-http'
        priority: 100
        rules: [
          {
            name: 'dnat-tcp8081-to-spoke1-80'
            ruleType: 'NatRule'
            description: 'DNAT port 8081 to Spoke1'
            destinationAddresses: [
              wthafw.properties.hubIPAddresses.publicIPs.addresses[0].address
            ]
            destinationPorts: [
              '8081'
            ]
            ipProtocols: [
              'tcp'
            ]
            sourceAddresses: [
              '*'
            ]
            translatedAddress: wthspoke1vmnic.properties.ipConfigurations[0].properties.privateIPAddress
            translatedPort: '80'
          }
          {
            name: 'dnat-tcp8082-to-spoke1-80'
            ruleType: 'NatRule'
            description: 'DNAT port 8082 to Spoke2'
            destinationAddresses: [
              wthafw.properties.hubIPAddresses.publicIPs.addresses[0].address
            ]
            destinationPorts: [
              '8082'
            ]
            ipProtocols: [
              'tcp'
            ]
            sourceAddresses: [
              '*'
            ]
            translatedAddress: wthspoke2vmnic.properties.ipConfigurations[0].properties.privateIPAddress
            translatedPort: '80'
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        action: {
          type: 'DNAT'
        }
        name: 'dnat-rdp'
        priority: 101
        rules: [
          {
            name: 'dnat-tcp33891-to-spoke1-33899'
            ruleType: 'NatRule'
            description: 'DNAT port 33891 to Spoke1'
            destinationAddresses: [
              wthafw.properties.hubIPAddresses.publicIPs.addresses[0].address
            ]
            destinationPorts: [
              '33891'
            ]
            ipProtocols: [
              'tcp'
            ]
            sourceAddresses: [
              '*'
            ]
            translatedAddress: wthspoke1vmnic.properties.ipConfigurations[0].properties.privateIPAddress
            translatedPort: '33899'
          }
          {
            name: 'dnat-tcp33892-to-spoke1-33899'
            ruleType: 'NatRule'
            description: 'DNAT port 33892 to Spoke2'
            destinationAddresses: [
              wthafw.properties.hubIPAddresses.publicIPs.addresses[0].address
            ]
            destinationPorts: [
              '33892'
            ]
            ipProtocols: [
              'tcp'
            ]
            sourceAddresses: [
              '*'
            ]
            translatedAddress: wthspoke2vmnic.properties.ipConfigurations[0].properties.privateIPAddress
            translatedPort: '33899'
          }
        ]
      }
    ]
  }
}

resource wthafwrcgnet 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  name: '${wthafwpolicy.name}/WTH_NetworkRulesCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'allow-network-rules'
        priority:200
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-any-to-any'
            description: 'Allow any traffic to any destination'
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '*'
            ]
            sourceAddresses: [
              '*'
            ]
            ipProtocols: [
              'Any'
            ]
          }
        ]
      }
    ]
  }
  dependsOn: [
    wthafwrcgdnat
  ]
} 

resource wthafwrcgapp 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  name: '${wthafwpolicy.name}/WTH_AppRulesCollectionGroup'
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        priority: 300
        name: 'allow-apprules'
        rules: []
      }
    ]
  }
  dependsOn: [
    wthafwrcgnet
  ]
}

