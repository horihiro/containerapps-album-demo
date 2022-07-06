targetScope = 'resourceGroup'

param name string
param envName string
param imageName string
param location string = resourceGroup().location
param env array = []
param daprAppId string
param ingressEnabled bool = false
param ingressTargetPort int = 3000
param externalIngressEnabled bool = false
param daprAppPort int = 3000

param secretName string = 'reg-pswd-${newGuid()}'

var acrUser = first(split(imageName, '.'))
var containerName = first(split(last(split(imageName, '/')), ':'))

resource containerenv 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: envName
}

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: acrUser
}

resource containerapp 'Microsoft.App/containerApps@2022-03-01' = {
  location: location
  name: name
  properties: {
    configuration: {
      dapr: empty(daprAppId) ? {} : {
        enabled: true
        appId: daprAppId
        appPort: daprAppPort
      }
      ingress: ingressEnabled ? {
        external: externalIngressEnabled
        targetPort: ingressTargetPort
      } : null
      registries: [
        {
          server: acr.properties.loginServer
          username: acrUser
          passwordSecretRef: secretName
        }
      ]
      secrets: [
        {
          name: secretName
          value: acr.listCredentials().passwords[0].value
        }
      ]
    }
    managedEnvironmentId: containerenv.id
    template: {
      containers: [
        {
          name: containerName
          env: env
          image: imageName
          resources: {
            cpu: '0.5'
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

var url = ingressEnabled ? '${containerapp.name}${externalIngressEnabled ? '.internal' : ''}.${containerenv.properties.defaultDomain}' : ''
output appuri string = url
