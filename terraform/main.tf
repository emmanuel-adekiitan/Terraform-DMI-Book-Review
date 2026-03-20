provider "azurerm" {
  features {}
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

# 3. DATABASE
module "database" {
  source              = "./modules/database"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_id             = module.network.vnet_id
  db_subnet_id        = module.network.db_subnet_id
  db_password         = var.db_password
}

# 4. COMPUTE (This is likely the missing block!)
module "compute" {
  source              = "./modules/compute"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  web_subnet_ids      = module.network.web_subnet_ids
  app_subnet_ids      = module.network.app_subnet_ids
  nsg_web_id          = module.security.nsg_web_id
  nsg_app_id          = module.security.nsg_app_id
}

# 5. LOAD BALANCER
module "loadbalancer" {
  source              = "./modules/loadbalancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  appgw_subnet_id     = module.network.appgw_subnet_id
  app_subnet_id       = module.network.app_subnet_id
}