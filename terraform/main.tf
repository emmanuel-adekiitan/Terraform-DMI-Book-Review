provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-dmi-book-review-prod"
  location = var.location
}

# 1. NETWORKING
module "network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# 2. SECURITY
module "security" {
  source              = "./modules/security"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_id             = module.network.vnet_id
}

# 3. DB NSG ASSOCIATION (root-level to avoid circular dependency between network and security modules)
resource "azurerm_subnet_network_security_group_association" "db_nsg" {
  for_each = tomap({
    "snet-db-01" = module.network.db_subnet_ids[0]
    "snet-db-02" = module.network.db_subnet_ids[1]
  })
  subnet_id                 = each.value
  network_security_group_id = module.security.nsg_db_id
}

# 4. DATABASE
module "database" {
  source              = "./modules/database"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_id             = module.network.vnet_id
  db_subnet_id        = module.network.db_subnet_id
  db_admin_login      = var.db_admin_login
  db_password         = var.db_password
  db_sku_name         = var.db_sku_name
}

# 5. COMPUTE
module "compute" {
  source              = "./modules/compute"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  web_subnet_ids      = module.network.web_subnet_ids
  app_subnet_ids      = module.network.app_subnet_ids
  nsg_web_id          = module.security.nsg_web_id
  nsg_app_id          = module.security.nsg_app_id
}

# 6. LOAD BALANCER
module "loadbalancer" {
  source              = "./modules/loadbalancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  appgw_subnet_id     = module.network.appgw_subnet_id
  app_subnet_id       = module.network.app_subnet_id
}