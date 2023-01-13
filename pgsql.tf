resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_postgresql_server" "spoke01-pgsql" {
  name                = "spoke01-${random_string.random.result}-pgsql"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  sku_name = "GP_Gen5_2"

  storage_mb                   = 51200
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true


  administrator_login              = var.username
  administrator_login_password     = random_password.password.result
  version                          = "11"
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"

  threat_detection_policy {
    disabled_alerts      = []
    email_account_admins = false
    email_addresses      = []
    enabled              = true
    retention_days       = 0
  }
}

resource "azurerm_private_endpoint" "spoke01-pgsql-pe" {
  name                = "spoke01-${random_string.random.result}-pgsql-endpoint"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  subnet_id           = azurerm_subnet.vnet1-subnet.id

  private_service_connection {
    name                           = "spoke01-${random_string.random.result}-pgsql-privateserviceconnection"
    private_connection_resource_id = azurerm_postgresql_server.spoke01-pgsql.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-postgres"
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink-postgres-database-azure-com.id]
  }
}