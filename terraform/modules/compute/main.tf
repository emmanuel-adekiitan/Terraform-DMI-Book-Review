# 1. Create Network Interfaces for the Web VMs
resource "azurerm_network_interface" "web_nic" {
  count               = 2
  name                = "nic-web-0${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.web_subnet_ids[count.index]
    private_ip_address_allocation = "Dynamic"
  }
}

# 2. Link the NSG to the NICs
resource "azurerm_network_interface_security_group_association" "web_nic_sg" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.web_nic[count.index].id
  network_security_group_id = var.nsg_web_id
}

# 3. Create the Virtual Machines (Modified to match your current error)
resource "azurerm_linux_virtual_machine" "web_vms" {
  count               = 2
  name                = "vm-dmi-web-0${count.index + 1}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B2s"
  admin_username      = "bookadmin"
  network_interface_ids = [azurerm_network_interface.web_nic[count.index].id]

  admin_ssh_key {
    username   = "bookadmin"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab

    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    apt-get update && apt-get install -y nodejs nginx git
    npm install -g pm2
  EOF
  )
}