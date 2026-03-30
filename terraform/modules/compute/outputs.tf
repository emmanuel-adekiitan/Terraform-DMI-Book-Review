output "web_vm_ips" {
  value = azurerm_linux_virtual_machine.web_vms[*].private_ip_address
}

output "app_vm_ips" {
  value = azurerm_linux_virtual_machine.app_vms[*].private_ip_address
}