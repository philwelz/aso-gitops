resource "azurerm_user_assigned_identity" "aso" {
  name                = "uai-${var.prefix}-${var.stage}-aso"
  location            = azurerm_resource_group.aks-rg.location
  resource_group_name = azurerm_resource_group.aks-rg.name
  tags                = local.common_tags
}

resource "azurerm_federated_identity_credential" "aso" {
  name                = "fc-${var.prefix}-${var.stage}-aso"
  resource_group_name = azurerm_resource_group.aks-rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.aso.id
  subject             = "system:serviceaccount:azureserviceoperator-system:azureserviceoperator-default"
}

# Role assignment to be able to add resources to the subscription
resource "azurerm_role_assignment" "uai_aso_sub_owner" {
  scope                            = data.azurerm_subscription.current.id
  role_definition_name             = "Owner"
  principal_id                     = azurerm_user_assigned_identity.aso.principal_id
  skip_service_principal_aad_check = true
}

# create secret
resource "kubernetes_namespace" "aso" {
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_kubernetes_cluster_node_pool.workload
  ]

  metadata {
    name = "azureserviceoperator-system"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
    ]
  }
}

resource "kubernetes_secret_v1" "aso" {
  metadata {
    name      = "aso-controller-settings"
    namespace = kubernetes_namespace.aso.metadata.0.name
  }

  data = {
    AZURE_CLIENT_ID       = azurerm_user_assigned_identity.aso.client_id
    AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.id
    AZURE_TENANT_ID       = data.azurerm_subscription.current.tenant_id
  }

  type = "Opaque"
}
