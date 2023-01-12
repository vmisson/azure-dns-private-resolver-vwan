#######################################
# VNet1
#######################################
resource "azurerm_virtual_network" "vnet1" {
  name                = "spoke1-vnet"
  address_space       = ["10.0.1.0/24"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  dns_servers = [ azurerm_firewall.firewall.virtual_hub[0].private_ip_address ]
}

resource "azurerm_subnet" "vnet1-subnet" {
  name                 = "spoke1-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_hub_connection" "vnet1-vhub-connection" {
  name                      = "vhub-to-spoke1"
  virtual_hub_id            = azurerm_virtual_hub.virtual-hub.id
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id

  internet_security_enabled = true
  routing {
    associated_route_table_id = "${azurerm_virtual_hub.virtual-hub.id}/hubRouteTables/defaultRouteTable"
    propagated_route_table {
      labels = ["none"]      
      route_table_ids = ["${azurerm_virtual_hub.virtual-hub.id}/hubRouteTables/noneRouteTable"]
    }
  }
}

#######################################
# VNet2
#######################################
resource "azurerm_virtual_network" "vnet2" {
  name                = "spoke2-vnet"
  address_space       = ["10.0.2.0/24"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  dns_servers = [ azurerm_firewall.firewall.virtual_hub[0].private_ip_address ]
}

resource "azurerm_subnet" "vnet2-subnet" {
  name                 = "spoke2-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_virtual_hub_connection" "vnet2-vhub-connection" {
  name                      = "vhub-to-spoke2"
  virtual_hub_id            = azurerm_virtual_hub.virtual-hub.id
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id

  internet_security_enabled = true
  routing {
    associated_route_table_id = "${azurerm_virtual_hub.virtual-hub.id}/hubRouteTables/defaultRouteTable"
    propagated_route_table {
      labels = ["none"]
      route_table_ids = ["${azurerm_virtual_hub.virtual-hub.id}/hubRouteTables/noneRouteTable"]
    }
  }
}
