aksName="osm"
acrName="osmacr"
workspaceName="osmworkspace"
resourceGroupName="rg-osm-platform"
subscriptionName="AzureDev"
location="northeurope"
aadSecurityGroupSearch="janne" # Group has this name :)

# Login and set correct context
az login -o table
az account set --subscription $subscriptionName -o table
az account show -o table

subscriptionID=$(az account show -o tsv --query id)
az group create -l $location -n $resourceGroupName -o table

acrid=$(az acr create -l $location -g $resourceGroupName -n $acrName --sku Basic --query id -o tsv)
echo $acrid

az ad group list --display-name $aadSecurityGroupSearch
az ad group list --display-name $aadSecurityGroupSearch --query [].objectId -o tsv
aadAdmingGroup=$(az ad group list --display-name $aadSecurityGroupSearch --query [].objectId -o tsv)

workspaceid=$(az monitor log-analytics workspace create -g $resourceGroupName -n $workspaceName --query id -o tsv)
echo $workspaceid

az aks get-versions -l $location -o table

az aks create -g $resourceGroupName -n $aksName \
 --zones "1" --max-pods 150 --network-plugin azure --network-plugin azure \
 --node-count 1 --enable-cluster-autoscaler --min-count 1 --max-count 3 \
 --node-osdisk-type Ephemeral \
 --node-vm-size Standard_B2ms \
 --kubernetes-version 1.20.5 --enable-addons monitoring \
 --enable-managed-identity --enable-aad \
 --aad-admin-group-object-ids $aadAdmingGroup \
 --workspace-resource-id $workspaceid \
 --attach-acr $acrid -o table 
 
 # Update max surge for an existing node pool 
az aks nodepool update -n nodepool1 -g $resourceGroupName --cluster-name $aksName --max-surge 33%

sudo az aks install-cli
az aks get-credentials -n $aksName -g $resourceGroupName
kubectl get nodes
