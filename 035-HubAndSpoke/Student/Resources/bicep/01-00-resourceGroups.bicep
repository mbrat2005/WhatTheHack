param location string = 'eastus2'
param locationSecondary string = 'westus3'

targetScope = 'subscription'
//hub resources
resource wthrghub 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'wth-rg-hub'
  location: location
}

resource wthrgspoke01 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'wth-rg-spoke1'
  location: location
}

resource wthrgspoke02 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'wth-rg-spoke2'
  location: location
}

resource wthrgonprem 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'wth-rg-onprem'
  location: location
}

resource wthrgonprem2 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'wth-rg-onprem2'
  location: locationSecondary
}
