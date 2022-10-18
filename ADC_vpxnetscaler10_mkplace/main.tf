# data sources for existing resource_group, vnet and 3-subnets
data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

data "azurerm_subnet" "management_subnet" {
  name                 = var.management_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.resource_group.name
}

data "azurerm_subnet" "client_subnet" {
  name                 = var.client_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.resource_group.name
}

data "azurerm_subnet" "server_subnet" {
  name                 = var.server_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.resource_group.name
}

data "azurerm_network_security_group" "terraform-management-subnet-security-group" {
  name                = "nsg-nsip-citrixgw-sbox"
  resource_group_name = data.azurerm_resource_group.resource_group.name
}



data "azurerm_network_security_group" "terraform-client-subnet-security-group" {
  name                = "nsg-vip-citrixgw-sbox"
  resource_group_name = data.azurerm_resource_group.resource_group.name
}




data "azurerm_network_security_group" "terraform-server-subnet-security-group" {
  name                = "nsg-snet1-citrixgw-sbox"
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

/*
resource "azurerm_public_ip" "terraform-adc-management-public-ip" {
  name                = "terraform-adc-management-public-ip"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = var.location
  allocation_method   = "Static"

}
*/
resource "azurerm_network_interface" "terraform-adc-management-interface" {
  name                = "terraform-adc-management-interface"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "management"
    subnet_id                     = data.azurerm_subnet.management_subnet.id
    private_ip_address_allocation = "Dynamic"
   // public_ip_address_id          = azurerm_public_ip.terraform-adc-management-public-ip.id
  }

  //depends_on = [azurerm_subnet_network_security_group_association.management-subnet-association]
}
/*
resource "azurerm_public_ip" "terraform-adc-client-public-ip" {
  name                = "terraform-adc-client-public-ip"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = var.location
  allocation_method   = "Static"
}
*/
resource "azurerm_network_interface" "terraform-adc-client-interface" {
  name                = "terraform-adc-client-interface"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "client"
    subnet_id                     = data.azurerm_subnet.client_subnet.id
    private_ip_address_allocation = "Dynamic"
    //public_ip_address_id          = azurerm_public_ip.terraform-adc-client-public-ip.id
  }

  //depends_on = [azurerm_subnet_network_security_group_association.client-subnet-association]
}

resource "azurerm_network_interface" "terraform-adc-server-interface" {
  name                = "terraform-adc-server-interface"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "client"
    subnet_id                     = data.azurerm_subnet.server_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  }

# The Citrix ADC instance is deployed as a single instance with 3 separate NICs each in a separate subnet.
resource "azurerm_virtual_machine" "terraform-adc-machine" {
  name                = "terraform-adc-machine"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = var.location
  vm_size             = var.adc_vm_size

  network_interface_ids = [
    azurerm_network_interface.terraform-adc-management-interface.id,
    azurerm_network_interface.terraform-adc-client-interface.id,
    azurerm_network_interface.terraform-adc-server-interface.id,
  ]

  primary_network_interface_id = azurerm_network_interface.terraform-adc-management-interface.id

  os_profile {
    computer_name  = "Citrix-ADC-VPX"
    admin_username = var.adc_admin_username
    admin_password = var.adc_admin_password
    custom_data = jsonencode({
      "subnet_11" = data.azurerm_subnet.server_subnet.address_prefix,
      "pvt_ip_11" = azurerm_network_interface.terraform-adc-client-interface.private_ip_address,
      "subnet_12" = data.azurerm_subnet.client_subnet.address_prefix,
      "pvt_ip_12" = azurerm_network_interface.terraform-adc-server-interface.private_ip_address,
    })
  }

  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      key_data = file(var.ssh_public_key_file)
      path     = format("/home/%v/.ssh/authorized_keys", var.adc_admin_username)
    }
  }

  delete_os_disk_on_termination = true

  storage_os_disk {
    name              = "terraform-citrixadc-os-disk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  storage_image_reference {
    publisher = "citrix"
    offer     = "netscalervpx-130"
    sku       = "netscaler10enterprise"
    version   = "latest"
  }
/*
  plan {
    name      = "netscalervpxexpress"
    publisher = "citrix"
    product   = "netscalervpx-130"
  }
*/
 plan {
    name      = "netscaler10enterprise"
    publisher = "citrix"
    product   = "netscalervpx-130"
  }
  
}
