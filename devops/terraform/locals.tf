locals {
  resource_group               = "RG-${var.region}-${var.environment}-${var.project}"
  tfstate_stor_account         = lower("sa${var.environment}${var.project}tfstate")
  tfstate_stor_container       = "tfstate"
  vnet_name                    = "VNET-${var.region}-${var.environment}-${var.project}"
  cap_subnet                   = "SBNT-CAP-${var.region}-${var.environment}-${var.project}"
  priv_endpt_subnet            = "SBNT-PEP-${var.region}-${var.environment}-${var.project}"
  acr_name                     = "ACR${var.environment}${var.project}"
  acr_pep_name                 = "PEP-ACR-${var.region}-${var.environment}-${var.project}"
  redis_name                   = "RCA-${var.region}-${var.environment}-${var.project}"
  redis_pep_name               = "PEP-RCA-${var.region}-${var.environment}-${var.project}"
  cap_name                     = "CAP-${var.region}-${var.environment}-${var.project}"
  kv_name                      = "KV-${var.region}-${var.environment}-${var.project}"
  kv_pep_name                  = "PEP-KV-${var.region}-${var.environment}-${var.project}"
  log_analytics_workspace_name = "LAW-${var.region}-${var.environment}-${var.project}"
}