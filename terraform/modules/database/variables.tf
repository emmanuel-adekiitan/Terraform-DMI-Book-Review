variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The Azure region"
}

variable "vnet_id" {
  type        = string
  description = "The ID of the VNet for Private DNS linking"
}

variable "db_subnet_id" {
  type        = string
  description = "The delegated subnet ID for MySQL"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "The admin password for the database"
}