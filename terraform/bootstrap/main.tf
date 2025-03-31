// Remote Backend State Configuration & Storage
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.22.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  resource_prefix = "migration-${var.environment}"
  tags = {
    Environment = var.environment
    Project     = "Cloud Migration"
  }
}

resource "azurerm_resource_group" "state" {
  name     = "tfstate-rg"
  location = var.location
  tags     = merge(local.tags, { Purpose = "Terraform State Management" })
}

resource "azurerm_storage_account" "state" {
  name                     = "tfstatemigrationsa"
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true
  }

  tags = local.tags
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}
