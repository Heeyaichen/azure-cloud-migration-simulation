terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.22.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatemigrationsa"
    container_name       = "tfstate"
    key                  = "cm-dev.tfstate"
  }
}

provider "azurerm" {
  features {}
}

// Local variables
locals {
  resource_prefix = "migration-${var.environment}"
  tags = {
    Environment = var.environment
    Project     = "Cloud Migration"
  }
}

// Resource group
resource "azurerm_resource_group" "main" {
  name     = "${local.resource_prefix}-rg"
  location = var.location
  tags     = local.tags
}

// Container registry
resource "azurerm_container_registry" "main" {
  name                  = replace("${local.resource_prefix}-acr", "-", "")
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  sku                   = "Premium"
  admin_enabled         = false
  data_endpoint_enabled = true

  network_rule_set {
    default_action = "Allow"
  }

  tags = local.tags
}

// MySQL Database (Flexible Server)
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "${local.resource_prefix}-mysql"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  sku_name               = "B_Standard_B1ms"
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  version                = "8.0.21"

  storage {
    size_gb = 20
  }

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = local.tags
}

resource "azurerm_mysql_flexible_database" "main" {
  name                = var.mysql_database_name
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

// App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "${local.resource_prefix}-asp"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"

  tags = local.tags
}

// Web App for Containers
resource "azurerm_linux_web_app" "main" {
  name                = "${local.resource_prefix}-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image_name = "${azurerm_container_registry.main.login_server}/mysql_flask_app:v1"
    }
  }

  app_settings = {
    MYSQL_HOST     = azurerm_mysql_flexible_server.main.fqdn
    MYSQL_USER     = azurerm_mysql_flexible_server.main.administrator_login
    MYSQL_PASSWORD = var.mysql_admin_password
    MYSQL_DB       = azurerm_mysql_flexible_database.main.name
    SSL_CA         = "/app/DigiCertGlobalRootCA.crt.pem"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

// Firewall rule to allow access from Azure services)
resource "azurerm_mysql_flexible_server_firewall_rule" "app_service" {
  name                = "allow-app-service"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

// Monitoring
resource "azurerm_application_insights" "main" {
  name                = "${local.resource_prefix}-ai"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}

