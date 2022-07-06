
param location string = resourceGroup().location
param acrName string
param uiAppName string
param apiAppName string

resource containerregistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: acrName
}

module loganalytics 'loganalytcs.bicep' = {
  name: 'loganalytics-deploy'
  params: {
    name: 'la-containerapps-album'
    location: location
  }
}

module containerenv 'containerenv.bicep' = {
  name: 'containerenv-deploy'
  params: {
    name: 'ce-containerapps-album'
    location: location
    logAnalyticsName: loganalytics.outputs.name
  }
}

module containerAppApi 'containerapp.bicep' = {
  name: 'containerapp-api-deploy'
  params: {
    name: apiAppName
    location: location
    envName: containerenv.outputs.name
    ingressEnabled: false
    // ingressTargetPort: 3000
    // externalIngressEnabled: false
    daprAppId: apiAppName
    daprAppPort: 3000
    imageName: '${containerregistry.name}.azurecr.io/${apiAppName}:latest'
  }
}

module containerAppUi 'containerapp.bicep' = {
  name: 'containerapp-ui-deploy'
  params: {
    name: uiAppName
    location: location
    envName: containerenv.outputs.name
    ingressEnabled: true
    ingressTargetPort: 3000
    externalIngressEnabled: true
    daprAppId: uiAppName
    daprAppPort: 3000
    imageName: '${containerregistry.name}.azurecr.io/${uiAppName}:latest'
    env: [
      {
        name: 'API_BASE_URL'
        value: 'http://localhost:3500'
      }
      {
        name: 'API_APP_ID'
        value: apiAppName
      }
    ]
  }
}
