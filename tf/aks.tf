################################
####### Managed Identity #######
################################

# Create User Assigned Identity
resource "azurerm_user_assigned_identity" "aks" {
  name                = "uai-${var.prefix}-${var.stage}-aks"
  location            = azurerm_resource_group.aks-rg.location
  resource_group_name = azurerm_resource_group.aks-rg.name
  tags                = local.common_tags
}

################################
##### Role assignments AKS #####
################################

# Role assignment to be able to manage the virtual network
resource "azurerm_role_assignment" "aks_vnet_contributor" {
  scope                            = azurerm_resource_group.aks-rg.id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.aks.principal_id
  skip_service_principal_aad_check = true
}

# Role assignment to publish metrics
resource "azurerm_role_assignment" "aks_metrics_publisher" {
  scope                            = azurerm_kubernetes_cluster.aks.id
  role_definition_name             = "Monitoring Metrics Publisher"
  principal_id                     = azurerm_user_assigned_identity.aks.principal_id
  skip_service_principal_aad_check = true
}

################################
### Azure Kubernetes Service ###
################################

resource "azurerm_kubernetes_cluster" "aks" {
  name                   = "aks-${var.prefix}-${var.stage}"
  kubernetes_version     = var.kubernetes_version
  location               = azurerm_resource_group.aks-rg.location
  resource_group_name    = azurerm_resource_group.aks-rg.name
  dns_prefix             = "aks-${var.prefix}-${var.stage}"
  local_account_disabled = "false"
  oidc_issuer_enabled    = "true"
  tags                   = local.common_tags

  azure_active_directory_role_based_access_control {
    managed                = true
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = ["429bfc0b-dac5-4dd8-862a-831985f20e4d"]
    azure_rbac_enabled     = true
  }

  default_node_pool {
    name                         = "nodepool"
    node_count                   = 1
    vm_size                      = "Standard_D4ds_v5"
    os_disk_type                 = "Ephemeral"
    only_critical_addons_enabled = "true"
  }
  # Set user managed identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }
}

# Create Workload node pool
resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.aks.id
  orchestrator_version   = var.kubernetes_version
  name                   = "aks0workload"
  node_count             = 2
  vm_size                = "Standard_D2as_v5"
  enable_auto_scaling    = false
  enable_node_public_ip  = false
  enable_host_encryption = false
  max_pods               = 110
  tags                   = local.common_tags

  upgrade_settings {
    max_surge = "33%"
  }

  # increase the update timeout for this resource
  timeouts {
    update = "2h"
  }

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}
