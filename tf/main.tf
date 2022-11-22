################################
###### Fetch Information #######
################################

resource "azurerm_resource_group" "aks-rg" {
  name     = "rg-${var.prefix}-${var.stage}-aks"
  location = "West Europe"
  tags     = local.common_tags
}

# get current subscription
data "azurerm_subscription" "current" {
}

# get current client
data "azurerm_client_config" "current" {
}


# define locals which will not change accross environments
locals {
  # Common tags to be assigned to all resources
  common_tags = {
    env       = var.stage
    managedBy = data.azurerm_client_config.current.client_id
    project   = var.prefix
  }
}
