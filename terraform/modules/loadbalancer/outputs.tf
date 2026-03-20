output "public_ip" {
  value = azurerm_public_ip.appgw_pip.ip_address
}

output "web_backend_pool_id" {
  value = tolist(azurerm_application_gateway.main.backend_address_pool)[0].id
}

output "app_backend_pool_id" {
  value = azurerm_lb_backend_address_pool.app_pool.id
}