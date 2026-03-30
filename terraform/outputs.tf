output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "vnet_id" {
  description = "The ID of the production VNet"
  value       = module.network.vnet_id
}

output "database_fqdn" {
  description = "The fully qualified domain name of the MySQL server"
  value       = module.database.db_host
}

output "web_vm_private_ips" {
  description = "Private IPs of the Web Tier VMs"
  value       = module.compute.web_vm_ips
}

output "app_vm_private_ips" {
  description = "Private IPs of the App Tier VMs"
  value       = module.compute.app_vm_ips
}

output "application_gateway_public_ip" {
  description = "The public entry point for the Book Review App"
  value       = module.loadbalancer.public_ip
}