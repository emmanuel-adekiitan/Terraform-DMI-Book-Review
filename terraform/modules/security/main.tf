# Web NSG
resource "azurerm_network_security_group" "nsg_web" {
  name                = "nsg-dmi-web"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowAgWInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
}

# App NSG (Only allow Web Subnets)
resource "azurerm_network_security_group" "nsg_app" {
  name                = "nsg-dmi-app"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowWebToApp"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3001"
    source_address_prefixes    = ["10.0.1.0/24", "10.0.2.0/24"]
    destination_address_prefix = "*"
  }
}

# DB NSG (Only allow App Subnets)
resource "azurerm_network_security_group" "nsg_db" {
  name                = "nsg-dmi-db"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowAppToDB"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefixes    = ["10.0.3.0/24", "10.0.4.0/24"]
    destination_address_prefix = "*"
  }
}