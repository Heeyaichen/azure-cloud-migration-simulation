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
