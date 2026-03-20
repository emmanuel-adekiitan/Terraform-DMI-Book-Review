output "nsg_web_id" { value = azurerm_network_security_group.nsg_web.id }
output "nsg_app_id" { value = azurerm_network_security_group.nsg_app.id }
output "nsg_db_id"  { value = azurerm_network_security_group.nsg_db.id }