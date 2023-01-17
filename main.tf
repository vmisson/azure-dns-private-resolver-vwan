resource "azurerm_resource_group" "resource_group" {
  name     = var.name
  location = var.location
}

resource "random_string" "vpn-psk" {
  length  = 32
  special = false
}