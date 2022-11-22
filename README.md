# 1

## Pre-Requisites

### Azure CLI

```bash
# Register the AKS-ExtensionManager preview features
az feature register --namespace Microsoft.ContainerService -n AKS-ExtensionManager
# Register provider for cluster extensions
az provider register -n Microsoft.Kubernetes
az provider register -n Microsoft.ContainerService
az provider register -n Microsoft.KubernetesConfiguration
# Monitor the registration process.
az provider show -n Microsoft.Kubernetes -o table
az provider show -n Microsoft.KubernetesConfiguration -o table
az provider show -n Microsoft.ContainerService -o table
# Optional: Setup the Azure CLI extension for cluster extensions
az extension add -n k8s-configuration
az extension add -n k8s-extension
az extension list -o table
```

## Deploy

```bash
# What-if
az deployment sub what-if \
  --name AksBicepDeployment \
  --location westeurope \
  --template-file ./bicep/main.bicep
# Deploy
az deployment sub create \
  --name AksBicepDeployment \
  --location westeurope \
  --template-file ./bicep/main.bicep
```

## Useful commands

```bash
kubectl get fluxconfigs -A
kubectl get kustomizations -A
kubectl get gitrepositories -A
kubectl get helmreleases -A
kubectl get helmrepositories -A
```

## Useful docs

* [Tutorial: Use GitOps with Flux v2 in AKS](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-flux2)
* [Deploy and manage cluster extensions for AKS](https://docs.microsoft.com/en-us/azure/aks/cluster-extensions?tabs=azure-cli)
* [Cluster exensions - Overview](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/conceptual-extensions)
* [GitOps on Azure](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/conceptual-gitops-flux2)


```bicep
// ################################
// ############# Flux #############
// ################################

resource flux 'Microsoft.KubernetesConfiguration/extensions@2021-09-01' = {
  name: 'flux'
  scope: aksCluster
  properties: {
    autoUpgradeMinorVersion: true
    configurationProtectedSettings: {}
    configurationSettings: {
      'helm-controller.enabled': 'true' // enabled by default
      'source-controller.enabled': 'true' // enabled by default
      'kustomize-controller.enabled': 'true' // enabled by default
      'notification-controller.enabled': 'true' // enabled by default
      'image-automation-controller.enabled': 'true' // disabled by default
      'image-reflector-controller.enabled': 'true' // disabled by default
    }
    extensionType: 'microsoft.flux'
    scope: {
      cluster: {
        releaseNamespace: 'flux-system'
      }
    }
  }
}

// ################################
// ######### Flux Config ##########
// ################################

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2021-11-01-preview' = {
  name: 'flux-config'
  scope: aksCluster
  dependsOn: [
    flux
  ]
  properties: {
    scope: 'cluster'
    namespace: 'flux-system'
    sourceKind: 'GitRepository'
    suspend: false

    gitRepository: {
      url: 'https://github.com/whiteducksoftware/fluxcd-example'
      timeoutInSeconds: 600
      syncIntervalInSeconds: 600
      repositoryRef: {
        branch: 'main'
      }

    }
    kustomizations: {
      cluster: {
        path: './clusters/${stage}'
        dependsOn: []
        timeoutInSeconds: 600
        syncIntervalInSeconds: 600
        validation: 'server'
        prune: true
      }
    //   apps: {
    //     path: './apps/staging'
    //     dependsOn: [
    //       {
    //         kustomizationName: 'infra'
    //       }
    //     ]
    //     timeoutInSeconds: 600
    //     syncIntervalInSeconds: 600
    //     retryIntervalInSeconds: 600
    //     prune: true
    //   }
    }
  }
}
```
