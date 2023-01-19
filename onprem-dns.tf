resource "azurerm_private_dns_resolver" "onpremise-dnsresolver" {
  name                = "onpremise-dns-resolver"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  virtual_network_id  = azurerm_virtual_network.onpremise-vnet.id
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "onpremise-dns-inboundendpoint" {
  name                    = "onpremise-dns-inbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.onpremise-dnsresolver.id
  location                = azurerm_private_dns_resolver.onpremise-dnsresolver.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.onpremise-dns-inbound-subnet.id
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "onpremise-dns-outboundendpoint" {
  name                    = "onpremise-dns-outbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.onpremise-dnsresolver.id
  location                = azurerm_private_dns_resolver.onpremise-dnsresolver.location
  subnet_id               = azurerm_subnet.onpremise-dns-outbound-subnet.id
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "onpremise-dnsruleset" {
  name                                       = "onpremise-dns-ruleset"
  resource_group_name                        = azurerm_resource_group.resource_group.name
  location                                   = azurerm_resource_group.resource_group.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.onpremise-dns-outboundendpoint.id]
}

resource "azurerm_private_dns_resolver_virtual_network_link" "link-onpremise-dnsruleset-dnsvnet" {
  name                      = "link-dns-onprem"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.onpremise-dnsruleset.id
  virtual_network_id        = azurerm_virtual_network.onpremise-vnet.id
}


resource "azurerm_private_dns_zone" "dns-zone-onpremise" {
  name                = "${var.name}.onprem"
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_private_dns_a_record" "azure-record-vm3" {
  name                = var.vm3-name
  zone_name           = azurerm_private_dns_zone.dns-zone-onpremise.name
  resource_group_name = azurerm_resource_group.resource_group.name
  ttl                 = 60
  records             = [azurerm_network_interface.vm3-nic1.private_ip_address]
}

resource "azurerm_private_dns_zone_virtual_network_link" "virtual-network-link-onpremise-zone" {
  name                  = "link-onpremise-zone"
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.dns-zone-onpremise.name
  virtual_network_id    = azurerm_virtual_network.onpremise-vnet.id
}
