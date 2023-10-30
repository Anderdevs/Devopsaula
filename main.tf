provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "senacgrupo" {
  name     = "senac-resource-group"
  location = "East US"
}

resource "azurerm_virtual_network" "senacgrupo" {
  name                = "senac-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.senacgrupo.location
  resource_group_name = azurerm_resource_group.senacgrupo.name
}

resource "azurerm_subnet" "senacgrupo" {
  name                 = "senac-subnet"
  resource_group_name  = azurerm_resource_group.senacgrupo.name
  virtual_network_name = azurerm_virtual_network.senacgrupo.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "senacgrupo" {
  name                = "senac-nsg"
  location            = azurerm_resource_group.senacgrupo.location
  resource_group_name = azurerm_resource_group.senacgrupo.name

  security_rule {
    name                       = "mongodb"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "27017"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ssh"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "mongodb" {
  name                = "mongodb-nic"
  location            = azurerm_resource_group.senacgrupo.location
  resource_group_name = azurerm_resource_group.senacgrupo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.senacgrupo.id
    private_ip_address_allocation = "Dynamic"
  }

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.senacgrupo.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.mongodb.id
    primary                       = true
  }
}

resource "azurerm_virtual_machine" "mongodb" {
  name                  = "mongodb-vm"
  location              = azurerm_resource_group.senacgrupo.location
  resource_group_name   = azurerm_resource_group.senacgrupo.name
  network_interface_ids = [azurerm_network_interface.mongodb.id]
  vm_size               = "Standard_DS2_v2"

  storage_os_disk {
    name              = "mongodb-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "mongodb"
    admin_username = "senac"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_network_interface" "app" {
  name                = "app-nic"
  location            = azurerm_resource_group.senacgrupo.location
  resource_group_name = azurerm_resource_group.senacgrupo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.senacgrupo.id
    private_ip_address_allocation = "Dynamic"
  }

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.senacgrupo.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.app.id
    primary                       = true
  }
}

resource "azurerm_virtual_machine" "app" {
  name                  = "app-vm"
  location              = azurerm_resource_group.senacgrupo.location
  resource_group_name   = azurerm_resource_group.senacgrupo.name
  network_interface_ids = [azurerm_network_interface.app.id]
  vm_size               = "Standard_DS2_v2"

  storage_os_disk {
    name              = "app-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "app"
    admin_username = "senac"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_public_ip" "mongodb" {
  name                = "mongodb-ip"
  location            = azurerm_resource_group.senacgrupo.location
  resource_group_name = azurerm_resource_group.senacgrupo.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "app" {
  name                = "app-ip"
  location            = azurerm_resource_group.senacgrupo.location
  resource_group_name = azurerm_resource_group.senacgrupo.name
  allocation_method   = "Dynamic"
}

