resource "azurerm_virtual_network" "onpremise-vnet" {
  name                = "onpremise-vnet"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  address_space       = ["10.100.0.0/21"]
  dns_servers         = ["10.100.2.4"]
}

resource "azurerm_subnet" "onpremise-gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.onpremise-vnet.name
  address_prefixes     = ["10.100.0.0/26"]
}

resource "azurerm_subnet" "onpremise-workload-subnet" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.onpremise-vnet.name
  address_prefixes     = ["10.100.1.0/24"]
}

resource "azurerm_subnet" "onpremise-dns-inbound-subnet" {
  name                 = "snet-dns-inbound"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.onpremise-vnet.name
  address_prefixes     = ["10.100.2.0/28"]
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
  address_prefixes     = ["10.100.2.16/28"]
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
