variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "web_subnet_ids"      { type = list(string) }
variable "app_subnet_ids"      { type = list(string) }
variable "nsg_web_id"          { type = string }
variable "nsg_app_id"          { type = string }