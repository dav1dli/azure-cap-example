terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

resource "azurerm_redis_cache" "redis" {
  name                  = var.name
  location              = var.location
  resource_group_name   = var.resource_group_name
  capacity              = var.capacity
  family                = var.family
  sku_name              = var.sku_name
  enable_non_ssl_port   = var.enable_non_ssl_port
  minimum_tls_version = "1.2"
  identity {
    type = "SystemAssigned"
  }
  redis_configuration {
  }
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}