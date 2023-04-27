data "azurerm_client_config" "current" {
}

resource "azurerm_resource_group" "rg" {
    name     = local.resource_group
    location = var.location
    tags     = var.tags
}

module "log_analytics_workspace" {
  source                           = "./modules/analytics"
  name                             = local.log_analytics_workspace_name
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
}

module "vnet" {
    source              = "./modules/vnet"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    vnet_name           = local.vnet_name
    address_space       = var.vnet_address_space

    subnets = [
        {
          name : local.cap_subnet
          address_prefixes : var.cap_subnet_address_prefix
        },
        {
          name : local.priv_endpt_subnet
          address_prefixes : var.priv_endpt_subnet_address_prefix
        },
  ]
}

module "acr" {
  source                       = "./modules/acr"
  name                         = local.acr_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  sku                          = var.acr_sku
  admin_enabled                = var.acr_admin_enabled
}
module "acr_private_dns_zone" {
  source                       = "./modules/private_dns_zone"
  name                         = "privatelink.azurecr.io"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_networks_to_link     = {
    (module.vnet.name) = {
      subscription_id = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg.name
    }
  }
}
module "acr_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = local.acr_pep_name
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnet_ids[local.priv_endpt_subnet]
  tags                           = var.tags
  private_connection_resource_id = module.acr.id
  is_manual_connection           = false
  subresource_name               = "registry"
  private_dns_zone_group_name    = "AcrPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.acr_private_dns_zone.id]
}
module "key_vault" {
  source                          = "./modules/keyvault"
  name                            = local.kv_name
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.key_vault_sku_name
  tags                            = var.tags
  enabled_for_deployment          = var.key_vault_enabled_for_deployment
  enabled_for_disk_encryption     = var.key_vault_enabled_for_disk_encryption
  enabled_for_template_deployment = var.key_vault_enabled_for_template_deployment
  enable_rbac_authorization       = var.key_vault_enable_rbac_authorization
  purge_protection_enabled        = var.key_vault_purge_protection_enabled
  soft_delete_retention_days      = var.key_vault_soft_delete_retention_days
  bypass                          = var.key_vault_bypass
  default_action                  = var.key_vault_default_action
}
module "kv_private_dns_zone" {
  source                       = "./modules/private_dns_zone"
  name                         = "privatelink.vaultcore.azure.net"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_networks_to_link     = {
    (module.vnet.name) = {
      subscription_id = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg.name
    }
  }
}
module "kv_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = local.kv_pep_name
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnet_ids[local.priv_endpt_subnet]
  tags                           = var.tags
  private_connection_resource_id = module.key_vault.id
  is_manual_connection           = false
  subresource_name               = "vault"
  private_dns_zone_group_name    = "KeyVaultPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.kv_private_dns_zone.id]
}

module "cap_environment" {
  source                       = "./modules/cap_env"
  name                         = local. cap_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  log_analytics_workspace_id   = module.log_analytics_workspace.id
  infrastructure_subnet_id     = module.vnet.subnet_ids[local.cap_subnet]
}
module "redis" {
  source                       = "./modules/redis"
  name                         = local.redis_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  enable_non_ssl_port          = true
}
module "redis_private_dns_zone" {
  source                       = "./modules/private_dns_zone"
  name                         = "privatelink.redis.cache.windows.net"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_networks_to_link     = {
    (module.vnet.name) = {
      subscription_id = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.rg.name
    }
  }
}
module "redis_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = local.redis_pep_name
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnet_ids[local.priv_endpt_subnet]
  tags                           = var.tags
  private_connection_resource_id = module.redis.id
  is_manual_connection           = false
  subresource_name               = "redisCache"
  private_dns_zone_group_name    = "RedisPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.redis_private_dns_zone.id]
  depends_on                     = [module.redis]
}
resource "azurerm_key_vault_secret" "redis_password" {
  key_vault_id = module.key_vault.id
  name         = "redis-password"
  value        = module.redis.primary_access_key
  depends_on   = [module.redis]
}