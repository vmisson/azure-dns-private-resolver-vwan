resource "azurerm_resource_group" "resource_group" {
  name     = var.name
  location = var.location
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_string" "vpn-psk" {
  length  = 32
  special = false
}