resource "azurerm_virtual_wan" "virtual-wan" {
  name                = "vwan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  type                = "Standard"
}

resource "azurerm_virtual_hub" "virtual-hub" {
  name                = "vhub"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  virtual_wan_id      = azurerm_virtual_wan.virtual-wan.id
  address_prefix      = "10.0.0.0/24"
  sku                 = "Standard"
}

resource "azurerm_firewall" "firewall" {
  name                = "firewall"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  sku_name            = "AZFW_Hub"
  sku_tier            = "Standard"
  virtual_hub {
    virtual_hub_id = azurerm_virtual_hub.virtual-hub.id
  }
  firewall_policy_id = azurerm_firewall_policy.firewall-policy.id
}

resource "azurerm_firewall_policy" "firewall-policy" {
  name                = "firewall-policy"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  dns {
    proxy_enabled = true
    servers = [azurerm_private_dns_resolver_inbound_endpoint.dns-inboundendpoint.ip_configurations[0].private_ip_address]
  }
}

resource "azurerm_log_analytics_workspace" "log-analytics" {
  name                = "log-analytics"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic-setting" {
  name               = "firewall-diagnostic-setting"
  target_resource_id = azurerm_firewall.firewall.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log-analytics.id
  log_analytics_destination_type = "AzureDiagnostics"

  log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}