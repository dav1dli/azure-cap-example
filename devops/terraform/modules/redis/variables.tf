variable "name" {
  description = "(Required) Specifies the name of the Regis cache. Changing this forces a new resource to be created."
  type        = string
}
variable "resource_group_name" {
  description = "(Required) The name of the resource group in which to create the Regis cache. Changing this forces a new resource to be created."
  type        = string
}
variable "location" {
  description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}
variable "capacity" {
  description = "(Required) The size of the Redis cache to deploy."
  type        = string
  default     = "0"
}
variable "family" {
  description = "(Required) The SKU family/pricing group to use."
  type        = string
  default     = "C"
  validation {
    condition = contains(["C", "P"], var.family)
    error_message = "The regis family/pricing group is invalid."
  }
}
variable "sku_name" {
  description = "(Required) The SKU name of the Redis cache. Possible values are Basic, Standard and Premium. Defaults to Standard"
  type        = string
  default     = "Standard"

  validation {
    condition = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "The container registry sku is invalid."
  }
}
variable "enable_non_ssl_port" {
  description = "(Optional) Specifies whether the non-ssl port is enabled."
  type        = string
  default     = false
}
variable "enable_authentication" {
  description = "(Optional) Specifies whether the authentication is enabled."
  type        = string
  default     = true
}
variable "tags" {
  description = "(Optional) A mapping of tags to assign to the resource."
  type        = map(any)
  default     = {}
}