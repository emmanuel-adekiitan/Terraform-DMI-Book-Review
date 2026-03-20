variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "vnet_id" {
  type        = string
  description = "The ID of the VNet"
}