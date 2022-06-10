With the following commands, you can provision a cluster with the [az CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).
If you already had the Azure CLI (and aks-preview extension) installed, please update them via `az upgrade` (and `az extension update -n aks-preview`).

```
export CLUSTER_NAME=tap-demo
az login
az group create --location germanywestcentral --name ${CLUSTER_NAME}

# Add pod security policies support preview (required for learningcenter)
az extension add --name aks-preview
az feature register --name PodSecurityPolicyPreview --namespace Microsoft.ContainerService
# Wait until the status is "Registered"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/PodSecurityPolicyPreview')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService

az aks create --resource-group ${CLUSTER_NAME} --name ${CLUSTER_NAME} --node-count 4 --enable-addons monitoring --node-vm-size Standard_DS2_v2 --node-osdisk-size 100 --enable-pod-security-policy

az aks get-credentials --resource-group ${CLUSTER_NAME} --name ${CLUSTER_NAME}

kubectl create clusterrolebinding tap-psp-rolebinding --group=system:authenticated --clusterrole=psp:privileged
```
