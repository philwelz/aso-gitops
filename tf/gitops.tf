resource "azapi_resource" "flux" {
  type      = "Microsoft.KubernetesConfiguration/extensions@2022-07-01"
  name      = "flux"
  parent_id = azurerm_kubernetes_cluster.aks.id
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_kubernetes_cluster_node_pool.workload
  ]

  body = jsonencode({
    properties = {
      extensionType                  = "microsoft.flux"
      autoUpgradeMinorVersion        = true
      configurationProtectedSettings = {}

      configurationSettings = {
        "multiTenancy.enforce"            = "false"
        "helm-controller.enabled"         = "true"
        "source-controller.enabled"       = "true"
        "kustomize-controller.enabled"    = "true"
        "notification-controller.enabled" = "true"
      }

      scope = {
        cluster = {
          releaseNamespace = "flux-system"
        }
      }
    }
  })
}

resource "azapi_resource" "flux_config" {
  type       = "Microsoft.KubernetesConfiguration/fluxConfigurations@2022-07-01"
  name       = "flux-config"
  parent_id  = azurerm_kubernetes_cluster.aks.id
  depends_on = [azapi_resource.flux]

  body = jsonencode({
    properties = {
      scope      = "cluster"
      namespace  = "flux-system"
      sourceKind = "GitRepository"
      suspend    = false

      gitRepository = {
        url                   = "https://github.com/philwelz/aso-gitops"
        timeoutInSeconds      = 60
        syncIntervalInSeconds = 60
        repositoryRef = {
          branch = "main"
        }
      }

      kustomizations = {
        cluster = {
          path                  = "./gitops/clusters/${var.stage}"
          dependsOn             = []
          timeoutInSeconds      = 60
          syncIntervalInSeconds = 60
          prune                 = true
        }
      }
    }
  })
}
