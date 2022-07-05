#!/bin/bash
CURRENT_DIR="$(dirname "$(dirname "$(dirname "$(realpath "${BASH_SOURCE:-0}")")")")"
echo ${CURRENT_DIR}
# exit 0

# ids=($(az account show | jq -r '.id,.tenantId'))
# subId=${ids[0]}
# tenantId=${ids[1]}
# # Retreive location list
# echo "Retrieving location list..."
# locations=($(az account list-locations | jq -r '.[] | select(.metadata.regionType == "Physical") | .name' | sort))

# # Input location
# while true
# do
#   echo -n "Enter location you want to deploy to: "
#   read location
#   if [[ " ${locations[*]} " =~ " ${location} " ]]; then
#     break;
#   fi
#   echo "\`${location}\` is invalid."
# done

# # Create a new resouce group
# while true
# do
#   echo -n "Enter resource group name: "
#   read rgName
#   az deployment sub create -l "${location}" --parameters "{ \"resourceGroupName\": { \"value\": \"${rgName}\" } }"  --template-file "${CURRENT_DIR}/azure/bicep/resourceGroup.bicep" >/dev/null && break
# done
# echo "Check the resource group by opening this url:"
# echo "https://portal.azure.com/#@${tenantId}/resource/subscriptions/${subId}/resourceGroups/${rgName}"

# while true
# do
#   echo -n "Type \"ok\" to proceed:"
#   read ok
#   if [ "${ok}" == "ok" ]; then break; fi
# done

# # Deploy a new ACR resource to Azure
# while true
# do
#   echo -n "Enter ACR resource name: "
#   read acrName
#   az deployment group create -g "${rgName}" --parameters "{ \"acrName\": { \"value\": \"${acrName}\" } }" --template-file "${CURRENT_DIR}/azure/bicep/containerregistry.bicep" >/dev/null && break
# done
# echo "Check the ACR resource by opening this url:"
# echo "https://portal.azure.com/#@${tenantId}/resource/subscriptions/${subId}/resourceGroups/${rgName}/providers/Microsoft.ContainerRegistry/registries/${acrName}"

# while true
# do
#   echo -n "Type \"ok\" to proceed:"
#   read ok
#   if [ "${ok}" == "ok" ]; then break; fi
# done

# Deploy and build new container images to Azure Container Registry
ls -d "${CURRENT_DIR}/*"

# Deploy LogAnalytics, Container App Env, Container Apps resources to Azure

