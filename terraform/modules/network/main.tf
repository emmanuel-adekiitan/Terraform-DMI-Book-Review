resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-dmi-br-prod"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

locals {
  subnets = {
    "snet-web-01" = { address = "10.0.1.0/24", zone = "1" }
    "snet-web-02" = { address = "10.0.2.0/24", zone = "2" }
    "snet-app-01" = { address = "10.0.3.0/24", zone = "1" }
    "snet-app-02" = { address = "10.0.4.0/24", zone = "2" }
    "snet-db-01"  = { address = "10.0.5.0/24", zone = "1" }
    "snet-db-02"  = { address = "10.0.6.0/24", zone = "2" }
  }
}

resource "azurerm_subnet" "subnets" {
  for_each             = local.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address]

  dynamic "delegation" {
    for_each = length(regexall("db", each.key)) > 0 ? [1] : []
    content {
      name = "mysql-delegation"
      service_delegation {
        name    = "Microsoft.DBforMySQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}

resource "azurerm_public_ip" "nat_pip" {
  name                = "pip-dmi-nat-gw"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gw" {
  name                = "nat-dmi-br-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}

resource "azurerm_subnet_nat_gateway_association" "app_assoc" {
  for_each       = toset(["snet-app-01", "snet-app-02"])
  subnet_id      = azurerm_subnet.subnets[each.value].id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}