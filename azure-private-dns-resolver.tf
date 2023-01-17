resource "azurerm_virtual_network" "dns-vnet" {
  name                = "dns-vnet"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = ["10.10.0.0/24"]
}

resource "azurerm_subnet" "dns-inbound-subnet" {
  name                 = "dns-inbound-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.dns-vnet.name
  address_prefixes     = ["10.10.0.0/28"]
  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_subnet" "dns-outbound-subnet" {
  name                 = "dns-outbound-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.dns-vnet.name
  address_prefixes     = ["10.10.0.16/28"]
  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_virtual_hub_connection" "dns-vhub-connection" {
  name                      = "vhub-to-dns"
  virtual_hub_id            = azurerm_virtual_hub.virtual-hub.id
  remote_virtual_network_id = azurerm_virtual_network.dns-vnet.id

  internet_security_enabled = true
  routing {
    associated_route_table_id = "${azurerm_virtual_hub.virtual-hub.id}/hubRouteTables/defaultRouteTable"
    propagated_route_table {
      labels          = ["none"]
      route_table_ids = ["${azurerm_virtual_hub.virtual-hub.id}/hubRouteTables/noneRouteTable"]
    }
  }
}


resource "azurerm_private_dns_resolver" "dnsresolver" {
  name                = "dns-resolver"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  virtual_network_id  = azurerm_virtual_network.dns-vnet.id
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "dns-inboundendpoint" {
  name                    = "dns-inbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.dnsresolver.id
  location                = azurerm_private_dns_resolver.dnsresolver.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.dns-inbound-subnet.id
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "dns-outboundendpoint" {
  name                    = "dns-outbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.dnsresolver.id
  location                = azurerm_private_dns_resolver.dnsresolver.location
  subnet_id               = azurerm_subnet.dns-outbound-subnet.id
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "dnsruleset" {
  name                                       = "dns-ruleset"
  resource_group_name                        = azurerm_resource_group.resource_group.name
  location                                   = azurerm_resource_group.resource_group.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.dns-outboundendpoint.id]
}

resource "azurerm_private_dns_resolver_virtual_network_link" "link-dnsruleset-dnsvnet" {
  name                      = "link-dns-vnet"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.dnsruleset.id
  virtual_network_id        = azurerm_virtual_network.dns-vnet.id
}


resource "azurerm_private_dns_zone" "dns-zone-azure" {
  name                = "${var.name}.azure"
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_private_dns_a_record" "azure-record-vm1" {
  name                = var.vm1-name
  zone_name           = azurerm_private_dns_zone.dns-zone-azure.name
  resource_group_name = azurerm_resource_group.resource_group.name
  ttl                 = 60
  records             = [azurerm_network_interface.vm1-nic1.private_ip_address]
}

resource "azurerm_private_dns_a_record" "azure-record-vm2" {
  name                = var.vm2-name
  zone_name           = azurerm_private_dns_zone.dns-zone-azure.name
  resource_group_name = azurerm_resource_group.resource_group.name
  ttl                 = 60
  records             = [azurerm_network_interface.vm2-nic1.private_ip_address]
}

resource "azurerm_private_dns_zone_virtual_network_link" "virtual-network-link-azure-zone" {
  name                  = "link-azure-zone"
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.dns-zone-azure.name
  virtual_network_id    = azurerm_virtual_network.dns-vnet.id
}

resource "azurerm_private_dns_zone" "privatelink-postgres-database-azure-com" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink-postgres-hub" {
  name                  = "link-privatelink-postgres-database-azure-com"
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink-postgres-database-azure-com.name
  virtual_network_id    = azurerm_virtual_network.dns-vnet.id
}