terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "Bastion_Host_sec"
    storage_account_name = "prabhu1"
    container_name       = "container1"
    key                  = "vm.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "reasource_group" {
  name     = "reasource_group"
  location = "Central India"
}

resource "azurerm_virtual_network" "virtual-network" {
  name                = "virtual-network"
  resource_group_name = azurerm_resource_group.reasource_group.name
  location            = azurerm_resource_group.reasource_group.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "first-subnet"
  resource_group_name  = azurerm_resource_group.reasource_group.name
  virtual_network_name = azurerm_virtual_network.virtual-network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "network_interface_public_ip" {
  name                = "publicip-vm"
  location            = azurerm_resource_group.reasource_group.location
  resource_group_name = azurerm_resource_group.reasource_group.name
  sku                 = "Basic"
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "security_group" {
  name                = "security_group"
  location            = azurerm_resource_group.reasource_group.location
  resource_group_name = azurerm_resource_group.reasource_group.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "network_interface" {
  name                = "network-interface"
  location            = azurerm_resource_group.reasource_group.location
  resource_group_name = azurerm_resource_group.reasource_group.name

  ip_configuration {
    name                          = "first-ip-configuration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.network_interface_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "virtual_machine" {
  name                = "vm"
  location            = azurerm_resource_group.reasource_group.location
  resource_group_name = azurerm_resource_group.reasource_group.name
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  computer_name       = "first-vm"
  admin_password      = "Dba@1234"
  network_interface_ids = [
    azurerm_network_interface.network_interface.id,
  ]
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.virtual_machine.public_ip_address
}
output "private_ip_address" {
  value = azurerm_linux_virtual_machine.virtual_machine.private_ip_address
}
