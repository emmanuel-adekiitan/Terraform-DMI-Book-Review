output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "appgw_subnet_id" {
  value = azurerm_subnet.subnets["snet-web-01"].id
}

output "app_subnet_id" {
  value = azurerm_subnet.subnets["snet-app-01"].id
}

output "db_subnet_id" {
  value = azurerm_subnet.subnets["snet-db-01"].id
}

# Added these for the Compute module later
output "web_subnet_ids" {
  value = [azurerm_subnet.subnets["snet-web-01"].id, azurerm_subnet.subnets["snet-web-02"].id]
}

output "app_subnet_ids" {
  value = [azurerm_subnet.subnets["snet-app-01"].id, azurerm_subnet.subnets["snet-app-02"].id]
}