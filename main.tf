resource "azurerm_resource_group" "udacity_project_rg" {
  name     = "${var.prefix}-rg"
  location = var.location

  tags = {
    env = var.environment
  }
}

resource "azurerm_virtual_network" "udacity_project_vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.udacity_project_rg.location
  resource_group_name = azurerm_resource_group.udacity_project_rg.name
  address_space       = var.vnet_range

  tags = {
    env = var.environment
  }

}

resource "azurerm_subnet" "udacity_project_subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.udacity_project_rg.name
  virtual_network_name = azurerm_virtual_network.udacity_project_vnet.name
  address_prefixes     = var.subnet_range
}

resource "azurerm_public_ip" "udacity_project_public_ip" {
  name                = "${var.prefix}-public-ip"
  location            = azurerm_resource_group.udacity_project_rg.location
  resource_group_name = azurerm_resource_group.udacity_project_rg.name

  allocation_method = "Static"

  tags = {
    env = var.environment
  }


}

resource "azurerm_network_interface" "udacity_project_nic" {
  count               = var.vm_instance_count
  name                = "${var.prefix}-nic${count.index}"
  location            = azurerm_resource_group.udacity_project_rg.location
  resource_group_name = azurerm_resource_group.udacity_project_rg.name

  ip_configuration {
    name                          = "${var.prefix}-InternalIP-${count.index}"
    subnet_id                     = azurerm_subnet.udacity_project_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    env = var.environment
  }

}

resource "azurerm_network_security_group" "udacity_project_nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.udacity_project_rg.location
  resource_group_name = azurerm_resource_group.udacity_project_rg.name

  security_rule {
    name                       = "subNetTraffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ExternalTraffic"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = {
    env = var.environment
  }
}

resource "azurerm_subnet_network_security_group_association" "udacity_project_nsg_association" {
  subnet_id                 = azurerm_subnet.udacity_project_subnet.id
  network_security_group_id = azurerm_network_security_group.udacity_project_nsg.id
}




resource "azurerm_lb" "udacity_project_lb" {
  name                = "${var.prefix}-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.udacity_project_rg.name

  frontend_ip_configuration {
    name                 = "${var.prefix}-lb-pip"
    public_ip_address_id = azurerm_public_ip.udacity_project_public_ip.id
  }

  tags = {
    env = var.environment
  }

}

resource "azurerm_lb_backend_address_pool" "udacity_project_lb_backend_address_pool" {
  resource_group_name = azurerm_resource_group.udacity_project_rg.name
  loadbalancer_id     = azurerm_lb.udacity_project_lb.id
  name                = "BackEndAddressPool"
}


resource "azurerm_lb_probe" "udacity_project_lb_probe" {
  name                = "ssh-running-probe"
  resource_group_name = azurerm_resource_group.udacity_project_rg.name
  loadbalancer_id     = azurerm_lb.udacity_project_lb.id
  port                = 22
}

resource "azurerm_lb_nat_pool" "udacity_project_NAT_pool" {
  resource_group_name            = azurerm_resource_group.udacity_project_rg.name
  loadbalancer_id                = azurerm_lb.udacity_project_lb.id
  name                           = "${var.prefix}-lb-NATpool"
  protocol                       = "Tcp"
  frontend_port_start            = 1
  frontend_port_end              = 65534
  backend_port                   = 22
  frontend_ip_configuration_name = "${var.prefix}-lb-pip"
}


resource "azurerm_lb_rule" "udacity_project_LB_rule" {
  resource_group_name            = azurerm_resource_group.udacity_project_rg.name
  loadbalancer_id                = azurerm_lb.udacity_project_lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "${var.prefix}-lb-pip"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.udacity_project_lb_backend_address_pool.id
  probe_id                       = azurerm_lb_probe.udacity_project_lb_probe.id
}

resource "azurerm_network_interface_backend_address_pool_association" "udacity_project_LB_backendpool_association" {
  count                   = var.vm_instance_count
  network_interface_id    = element(azurerm_network_interface.udacity_project_nic.*.id, count.index)
  ip_configuration_name   = "${var.prefix}-InternalIP-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.udacity_project_lb_backend_address_pool.id
}


resource "azurerm_availability_set" "udacity_project_AvSet" {
  name                         = "${var.prefix}-AvS-01"
  location                     = azurerm_resource_group.udacity_project_rg.location
  resource_group_name          = azurerm_resource_group.udacity_project_rg.name
  platform_update_domain_count = 4
  platform_fault_domain_count  = 3

  tags = {
    env = var.environment
  }
}


resource "azurerm_linux_virtual_machine" "udacity_project_vm" {
  count                           = var.vm_instance_count
  name                            = "${var.prefix}-vm${count.index}"
  resource_group_name             = azurerm_resource_group.udacity_project_rg.name
  location                        = azurerm_resource_group.udacity_project_rg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  availability_set_id             = azurerm_availability_set.udacity_project_AvSet.id
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.udacity_project_nic[count.index].id,
  ]

  os_disk {
    name                 = "osdisk-${count.index}"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  source_image_id = var.image_resource_id

  tags = {
    env = var.environment
  }

}