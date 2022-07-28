param location string = 'eastus2'

resource wthcsrvm 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: 'wth-vm-ciscocsr01'
  scope: resourceGroup('wth-rg-onprem')
}

resource wthcsrnic 'Microsoft.Network/networkInterfaces@2022-01-01' existing = {
  name: 'wth-nic-csr01'
  scope: resourceGroup('wth-rg-onprem')
}

resource wthhubgwpip01 'Microsoft.Network/publicIPAddresses@2022-01-01' existing = {
  name: 'wth-pip-gw01'
  scope: resourceGroup('wth-rg-hub')
}

resource wthhubgwpip02 'Microsoft.Network/publicIPAddresses@2022-01-01' existing = {
  name: 'wth-pip-gw02'
  scope: resourceGroup('wth-rg-hub')
}

var csrScript = '''
config t

crypto ikev2 proposal azure-proposal
  encryption aes-cbc-256 aes-cbc-128 3des
  integrity sha1
  group 2
  exit
!
crypto ikev2 policy azure-policy
  proposal azure-proposal
  exit
!
crypto ikev2 keyring azure-keyring
  peer **GW0_Public_IP**
    address **GW0_Public_IP**
    pre-shared-key **PSK**
    exit
  peer **GW1_Public_IP**
    address **GW1_Public_IP**
    pre-shared-key **PSK**
    exit
  exit
!
crypto ikev2 profile azure-profile
  match address local interface GigabitEthernet1
  match identity remote address **GW0_Public_IP** 255.255.255.255
  match identity remote address **GW1_Public_IP** 255.255.255.255
  authentication remote pre-share
  authentication local pre-share
  keyring local azure-keyring
  exit
!
crypto ipsec transform-set azure-ipsec-proposal-set esp-aes 256 esp-sha-hmac
 mode tunnel
 exit

crypto ipsec profile azure-vti
  set transform-set azure-ipsec-proposal-set
  set ikev2-profile azure-profile
  set security-association lifetime kilobytes 102400000
  set security-association lifetime seconds 3600 
 exit
!
interface Tunnel0
 ip unnumbered GigabitEthernet1 
 ip tcp adjust-mss 1350
 tunnel source GigabitEthernet1
 tunnel mode ipsec ipv4
 tunnel destination **GW0_Public_IP**
 tunnel protection ipsec profile azure-vti
exit
!
interface Tunnel1
 ip unnumbered GigabitEthernet1 
 ip tcp adjust-mss 1350
 tunnel source GigabitEthernet1
 tunnel mode ipsec ipv4
 tunnel destination **GW1_Public_IP**
 tunnel protection ipsec profile azure-vti
exit

!
router bgp **BGP_ID**
 bgp router-id interface GigabitEthernet1
 bgp log-neighbor-changes
 redistribute connected
 neighbor **GW0_Private_IP** remote-as 65515
 neighbor **GW0_Private_IP** ebgp-multihop 5
 neighbor **GW0_Private_IP** update-source GigabitEthernet1
 neighbor **GW1_Private_IP** remote-as 65515
 neighbor **GW1_Private_IP** ebgp-multihop 5
 neighbor **GW1_Private_IP** update-source GigabitEthernet1
 maximum-paths eibgp 4
!
ip route **GW0_Private_IP** 255.255.255.255 Tunnel0
ip route **GW1_Private_IP** 255.255.255.255 Tunnel1
!
end
!
wr mem
'''

resource configcsr 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  name: '${wthcsrvm.name}/wth-vmextn-changerdpport33899'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      commandToExecute: 'ssh -o BatchMode=yes -o StrictHostKeyChecking=no admin-wth@'
    }
  }
}
