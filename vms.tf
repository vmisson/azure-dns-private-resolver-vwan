resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

#######################################
# VM1
#######################################
resource "azurerm_network_interface" "vm1-nic1" {
  name                = "${var.vm1-name}-nic1-site1"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.vnet1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = var.vm1-name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_DS1_v2"

  admin_username                  = var.username
  disable_password_authentication = false
  admin_password                  = random_password.password.result

  network_interface_ids = [
    azurerm_network_interface.vm1-nic1.id
  ]

  os_disk {
    name                 = "v${var.vm1-name}-od01"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  boot_diagnostics {}
}

#######################################
# VM2
#######################################
resource "azurerm_network_interface" "vm2-nic1" {
  name                = "${var.vm2-name}-nic1-site1"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.vnet2-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                = var.vm2-name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_DS1_v2"

  admin_username                  = var.username
  disable_password_authentication = false
  admin_password                  = random_password.password.result

  network_interface_ids = [
    azurerm_network_interface.vm2-nic1.id
  ]

  os_disk {
    name                 = "${var.vm2-name}-od01"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  boot_diagnostics {}
}

#######################################
# VM OnPrem
#######################################
resource "azurerm_network_interface" "vm3-nic1" {
  name                = "${var.vm3-name}-nic1-site1"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.onpremise-workload-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm3" {
  name                = var.vm3-name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_DS1_v2"

  admin_username                  = var.username
  disable_password_authentication = false
  admin_password                  = random_password.password.result

  network_interface_ids = [
    azurerm_network_interface.vm3-nic1.id
  ]

  os_disk {
    name                 = "${var.vm3-name}-od01"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  boot_diagnostics {}
}