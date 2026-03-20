resource "azurerm_private_dns_zone" "dns" {
  name                = "dmi.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "dmi-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = "mysql-dmi-prod-server"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = "dbadmin"
  administrator_password = var.db_password
  backup_retention_days  = 7
  delegated_subnet_id    = var.db_subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.dns.id
  sku_name               = "GP_Standard_D2ds_v4" # General Purpose for Zone Redundancy
  version                = "8.0.21"

  high_availability {
    mode = "ZoneRedundant"
  }
}