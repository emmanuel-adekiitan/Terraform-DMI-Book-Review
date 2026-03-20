variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "appgw_subnet_id"     { type = string } # Subnet for Public Gateway
variable "app_subnet_id"       { type = string } # Subnet for Internal LB