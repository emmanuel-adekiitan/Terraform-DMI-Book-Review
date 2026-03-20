output "db_host" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}