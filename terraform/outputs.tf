output "web_app_url" {
  value = azurerm_linux_web_app.main.default_hostname
}

output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.main.fqdn
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "app_service_principal_id" {
  value = azurerm_linux_web_app.main.identity[0].principal_id
}

output "acr_name" {
  value = azurerm_container_registry.main.name
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "app_service_name" {
  value = azurerm_linux_web_app.main.name
}

output "role_assignment_id" {
  value       = azurerm_role_assignment.acr_pull.id
  description = "The ID of the role assignment for the App Service's managed identity to pull images from ACR."

}
