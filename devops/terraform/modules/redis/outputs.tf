output "name" {
  description = "Specifies the name of the Redis Instance."
  value       = azurerm_redis_cache.redis.name
}

output "id" {
  description = "Specifies the resource id of the Redis Instance."
  value       = azurerm_redis_cache.redis.id
}

output "resource_group_name" {
  description = "Specifies the name of the resource group."
  value       = var.resource_group_name
}

output "hostname" {
  description = "Specifies the hostname of the Redis Instance."
  value = azurerm_redis_cache.redis.hostname
}

output "primary_access_key" {
  description = "Specifies the Primary Access Key of the Redis Instance."
  value       = azurerm_redis_cache.redis.primary_access_key
}
