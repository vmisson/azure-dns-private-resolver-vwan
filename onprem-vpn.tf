resource "azurerm_vpn_gateway" "vpn-gateway" {
  name                = "vhub-vpn-gateway"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  virtual_hub_id      = azurerm_virtual_hub.virtual-hub.id
  scale_unit          = 1
}

resource "azurerm_vpn_site" "vpn-site-onprem" {
  name                = "OnPrem"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  virtual_wan_id      = azurerm_virtual_wan.virtual-wan.id

  link {
    name       = "onpremise-vpngw"
    ip_address = azurerm_public_ip.onpremise-vpngw-ip.ip_address
    bgp {
      asn             = 65000
      peering_address = azurerm_virtual_network_gateway.onpremise-gateway.bgp_settings[0].peering_addresses[0].default_addresses[0]
    }
  }
}

resource "azurerm_vpn_gateway_connection" "vpn-connection" {
  name               = "vpn-connection"
  vpn_gateway_id     = azurerm_vpn_gateway.vpn-gateway.id
  remote_vpn_site_id = azurerm_vpn_site.vpn-site-onprem.id

  vpn_link {
    name             = "gw001-pip"
    vpn_site_link_id = azurerm_vpn_site.vpn-site-onprem.link[0].id
    shared_key       = random_string.vpn-psk.result
    bgp_enabled      = true
  }
}

