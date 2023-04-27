output "env" {
  value = var.environment
}
output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}