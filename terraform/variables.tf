variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID"
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "The Azure region"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Password for MySQL Flexible Server"
}