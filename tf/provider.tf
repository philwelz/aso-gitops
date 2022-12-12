terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.31.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "=1.0.0"
    }
  }

  required_version = "=1.3.6"
}

provider "azurerm" {
  features {}
}

provider "azapi" {
}
