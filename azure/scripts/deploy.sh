#!/bin/bash
CURRENT_DIR="$(dirname "$(dirname "$(dirname "$(realpath "${BASH_SOURCE:-0}")")")")"

ids=($(az account show | jq -r '.id,.tenantId'))
if [ -z "${ids[*]}" ]; then exit 1; fi
subId=${ids[0]}
tenantId=${ids[1]}

# Retreive location list
echo "Retrieving location list..."
locations=($(az account list-locations | jq -r '.[] | select(.metadata.regionType == "Physical") | .name' | sort))

# Input location
while true
do
  echo -n "Enter location you want to deploy to: "
  read location
  if [[ " ${locations[*]} " =~ " ${location} " ]]; then
    break;
  fi
  echo "\`${location}\` is invalid."
done

# Create a new resouce group
while true
do
  echo -n "Enter resource group name: "
  read rgName
echo
  echo "  az deployment sub create \\"
  echo "    --location \"${location}\" \\"
  echo "    --parameters \"{ \\\"resourceGroupName\\\": { \\\"value\\\": \\\"${rgName}\\\" } }\" \\"
  echo "    --template-file \"${CURRENT_DIR}/azure/bicep/resourceGroup.bicep\""
  echo
  az deployment sub create --location "${location}" --parameters "{ \"resourceGroupName\": { \"value\": \"${rgName}\" } }"  --template-file "${CURRENT_DIR}/azure/bicep/resourceGroup.bicep" >/dev/null && break
done
echo
echo "Check the resource group by opening this url:"
echo "https://portal.azure.com/#@${tenantId}/resource/subscriptions/${subId}/resourceGroups/${rgName}"

echo
while true
do
  echo -n "Type \"ok\" to proceed: "
  read ok
  if [ "${ok}" == "ok" ]; then break; fi
done
echo

# Deploy a new ACR resource to Azure
while true
do
  echo -n "Enter ACR resource name: "
  read acrName
  echo
  echo "  az deployment group create \\"
  echo "    --resource-group \"${rgName}\" \\"
  echo "    --parameters \"{ \\\"acrName\\\": { \\\"value\\\": \\\"${acrName}\\\" } }\" \\"
  echo "    --template-file \"${CURRENT_DIR}/azure/bicep/containerregistry.bicep\""
  echo
  az deployment group create --resource-group "${rgName}" --parameters "{ \"acrName\": { \"value\": \"${acrName}\" } }" --template-file "${CURRENT_DIR}/azure/bicep/containerregistry.bicep" >/dev/null && break
done
echo
echo "Check the ACR resource by opening this url:"
echo "https://portal.azure.com/#@${tenantId}/resource/subscriptions/${subId}/resourceGroups/${rgName}/providers/Microsoft.ContainerRegistry/registries/${acrName}"

echo
while true
do
  echo -n "Type \"ok\" to proceed: "
  read ok
  if [ "${ok}" == "ok" ]; then break; fi
done
echo

# Deploy and build new container images to Azure Container Registry
cd "${CURRENT_DIR}"
apiImageList=($(ls -d */ | grep albumapi | awk '{ sub(/\/$/, ""); print }'))
uiImageList=($(ls -d */ | grep albumui | awk '{ sub(/\/$/, ""); print }'))
cd -  > /dev/null

for index in "${!uiImageList[@]}"
do
  [[ -z "$(find "${CURRENT_DIR}/${uiImageList[$index]}" -name "Dockerfile")" ]] && unset -v 'uiImageList[$index]'
done
uiImageList=("${uiImageList[@]}")
if [ "${#uiImageList[@]}" == "1" ]; then
  uiImageIndex=0
else
  echo "Select UI app image:"
  for index in "${!uiImageList[@]}";
  do
    echo "$index: ${uiImageList[$index]}"
  done
  while true
  do
    read i
    if [ ! -z "${uiImageList[${i}]}" ]; then break; fi
    echo "\`${i}\` is invalid."
    echo "Select again"
  done
fi
uiImage=${uiImageList[${i}]}
echo "  UI app: ${uiImage}"
uiDockerfileDir=$(dirname $(find "${CURRENT_DIR}/${uiImage}" -name "Dockerfile"))
echo
echo "  az acr build \\"
echo "    --registry \"${acrName}\" \\"
echo "    --image \"${acrName}.azurecr.io/${uiImage}:latest\" \\"
echo "    \"${uiDockerfileDir}\""
echo
az acr build -r "${acrName}" -t "${acrName}.azurecr.io/${uiImage}:latest" "${uiDockerfileDir}"

for index in "${!uiImageList[@]}"
do
  [[ -z "$(find "${CURRENT_DIR}/${apiImageList[$index]}" -name "Dockerfile")" ]] && unset -v '${apiImageList[$index]}'
done
apiImageList=("${apiImageList[@]}")
if [ "${#apiImageList[@]}" == "1" ]; then
  apiImageIndex=0
else
  echo "Select API app image:"
  for index in "${!apiImageList[@]}";
  do
    echo "$index: ${apiImageList[$index]}"
  done
  while true
  do
    read i
    if [ ! -z "${apiImageList[${i}]}" ]; then break; fi
    echo "\`${i}\` is invalid."
    echo "Select again"
  done
fi
apiImage=${apiImageList[${i}]}
echo
echo "  API app: ${apiImage}"

apiDockerfileDir=$(dirname $(find "${CURRENT_DIR}/${apiImage}" -name "Dockerfile"))
echo
echo "  az acr build \\"
echo "    --registry \"${acrName}\" \\"
echo "    --image \"${acrName}.azurecr.io/${apiImage}:latest\" \\"
echo "    \"${apiDockerfileDir}\""
echo
az acr build -r "${acrName}" -t "${acrName}.azurecr.io/${apiImage}:latest" "${apiDockerfileDir}"

echo
echo "Check the repositories in the ACR resource by opening this url:"
echo "https://portal.azure.com/#@${tenantId}/resource/subscriptions/${subId}/resourceGroups/${rgName}/providers/Microsoft.ContainerRegistry/registries/${acrName}/repository"

echo
while true
do
  echo -n "Type \"ok\" to proceed: "
  read ok
  if [ "${ok}" == "ok" ]; then break; fi
done

# Deploy LogAnalytics, Container App Env, Container Apps resources to Azure
echo
echo "  az deployment group create \\"
echo "    --resource-group \"${rgName}\" \\"
echo "    --parameters \"{ \\\"acrName\\\": { \\\"value\\\": \\\"${acrName}\\\" }, \\\"uiAppName\\\": { \\\"value\\\": \\\"${uiImage}\\\" }, \\\"apiAppName\\\": { \\\"value\\\": \\\"${apiImage}\\\" } }\" \\"
echo "    --template-file \"${CURRENT_DIR}/azure/bicep/main.bicep\""
echo
az deployment group create --resource-group "${rgName}" --parameters "{ \"acrName\": { \"value\": \"${acrName}\" }, \"uiAppName\": { \"value\": \"${uiImage}\" }, \"apiAppName\": { \"value\": \"${apiImage}\" } }" --template-file "${CURRENT_DIR}/azure/bicep/main.bicep" >/dev/null 

