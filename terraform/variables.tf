variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID"
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "The Azure region"
}

variable "db_admin_login" {
  type        = string
  description = "Administrator login username for MySQL Flexible Server"
}

variable "db_sku_name" {
  type        = string
  description = "SKU for MySQL Flexible Server (e.g. GP_Standard_D2ds_v4 or B_Standard_B1ms)"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Password for MySQL Flexible Server"
}