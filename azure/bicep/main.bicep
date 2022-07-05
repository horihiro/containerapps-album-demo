
param location string = resourceGroup().location

module loganalytics 'loganalytcs.bicep' = {
  name: 'loganalytics-deploy'
  params: {
    name: 'la-demo-containerapp'
    location: location
  }
}

module containerenv 'containerenv.bicep' = {
  name: 'containerenv-deploy'
  params: {
    name: 'ce-demo-containerapp'
    location: location
    logAnalyticsName: loganalytics.outputs.name
  }
}

module containerAppApi 'containerapp.bicep' = {
  name: 'containerapp-api-deploy'
  params: {
    name: 'ca-demo-apiapp'
    location: location
    envName: containerenv.outputs.name
    ingressEnabled: true
    ingressTargetPort: 3000
    externalIngressEnabled: false
    daprAppId: 'albumapi'
    daprAppPort: 3000
    imageName: 'acrhihorika.azurecr.io/containerapp-api:latest'
  }
}

module containerAppUi 'containerapp.bicep' = {
  name: 'containerapp-ui-deploy'
  params: {
    name: 'ca-demo-uiapp'
    location: location
    envName: containerenv.outputs.name
    ingressEnabled: true
    ingressTargetPort: 3000
    externalIngressEnabled: true
    daprAppId: 'albumui'
    daprAppPort: 3000
    imageName: 'acrhihorika.azurecr.io/containerapp-ui:latest'
    env: [
      {
        name: 'API_BASE_URL'
        value: 'http://localhost:3500'
      }
      {
        name: 'API_APP_ID'
        value: 'albumapi'
      }
    ]
  }
}
