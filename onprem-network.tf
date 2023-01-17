resource "azurerm_virtual_network" "onpremise-vnet" {
  name                = "onpremise-vnet"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  address_space       = ["10.233.0.0/21"]
  dns_servers         = ["10.233.2.4"]
}

resource "azurerm_subnet" "onpremise-gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.onpremise-vnet.name
  address_prefixes     = ["10.233.0.0/26"]
}

resource "azurerm_subnet" "onpremise-workload-subnet" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.onpremise-vnet.name
  address_prefixes     = ["10.233.1.0/24"]
}

resource "azurerm_subnet" "onpremise-dns-inbound-subnet" {
  name                 = "snet-dns-inbound"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.onpremise-vnet.name
  address_prefixes     = ["10.233.2.0/28"]
  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_subnet" "onpremise-dns-outbound-subnet" {
  name                 = "snet-dns-outbound"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.onpremise-vnet.name
  address_prefixes     = ["10.233.2.16/28"]
  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_public_ip" "onpremise-vpngw-ip" {
  name                = "onpremise-vpngw-ip"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "onpremise-gateway" {
  name                = "onpremise-vpngw"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = true
  sku           = "VpnGw1"

  bgp_settings {
    asn = "65000"
  }

  ip_configuration {
    name                          = "vnetGatewayIpConfig"
    public_ip_address_id          = azurerm_public_ip.onpremise-vpngw-ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.onpremise-gateway-subnet.id
  }
}

resource "azurerm_local_network_gateway" "vwan-vpn-lng" {
  name                = "vwan-vpn-lng"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  gateway_address     = sort(azurerm_vpn_gateway.vpn-gateway.bgp_settings[0].instance_0_bgp_peering_address[0].tunnel_ips)[1]

  bgp_settings {
    asn                 = "65515"
    bgp_peering_address = sort(azurerm_vpn_gateway.vpn-gateway.bgp_settings[0].instance_0_bgp_peering_address[0].default_ips)[0]
  }
}

resource "azurerm_virtual_network_gateway_connection" "onpremise-to-vwan" {
  name                = "onprem-to-vwan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.onpremise-gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.vwan-vpn-lng.id

  shared_key = random_string.vpn-psk.result
}

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
