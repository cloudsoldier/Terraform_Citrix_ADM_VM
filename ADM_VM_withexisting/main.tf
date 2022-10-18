terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.10.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "4f9fc577-70d6-4b0c-b0c9-3c7f24dae85f"
  tenant_id       =  "b8b4c61c-f1ca-4aff-a0bd-9c6f01c3eca5"
}


/*
locals {
  resource_group_name="kashirg"
  location="UK South"
  virtual_network={
    name="kashivnet"
    address_space="10.0.0.0/16"
  }

  */

# data sources for existing resource_group, vnet and 3-subnets
data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
}




data "azurerm_subnet" "server_subnet" {
  name                 = var.server_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.resource_group.name
}

data "azurerm_key_vault" "kv1-citrixgw-sbox" {
  name                = "kv1-citrixgw-sbox"
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

data "azurerm_key_vault_secret" "ADMvmpassword" {
  name         = "ADMvmpassword"
  key_vault_id = data.azurerm_key_vault.kv1-citrixgw-sbox.id
}


// Network interface one
resource "azurerm_network_interface" "appinterface1" {
  name                = "appinterface1"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.server_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vmpip.id
  }

depends_on = [
    data.azurerm_subnet.server_subnet
     ]
}





/*
resource "azurerm_public_ip" "vmpip" {
  name                = "vmpip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
 }
*/
// Network Security Group.

resource "azurerm_network_security_group" "kashvmNSG" {
  name                = "kashvmNSG"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

 tags = {
    owner = "Kash"
  }
  
}
/*
// NSG subnet association 

resource "azurerm_subnet_network_security_group_association" "kashvmnsglink" {
  subnet_id                 = azurerm_subnet.server_subnet.id
  network_security_group_id = azurerm_network_security_group.kashvmNSG.id
}
*/

resource "tls_private_key" "linuxkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "linuxpemkey"{
  filename = "linuxkey.pem"
  content=tls_private_key.linuxkey.private_key_pem
  depends_on = [
    tls_private_key.linuxkey
  ]
}
// virtual windows_virtual_machine
resource "azurerm_linux_virtual_machine" "linuxvm" {
  name                            = "ADMvmoncall"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "adminuser"
  admin_password                  = data.azurerm_key_vault_secret.ADMvmpassword.value
  disable_password_authentication = false
  custom_data = base64encode("registeragent -serviceurl whitehaven.agent.adm.cloud.com -activationcode 0e8c4f16-bf81-4b15-bb44-d29f179411ba")
  network_interface_ids = [
  azurerm_network_interface.appinterface1.id
  ]
  



/*
  admin_ssh_key {
     username="linuxuser"
     public_key = tls_private_key.linuxkey.public_key_openssh
   }
*/
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  

source_image_reference {
    publisher = "citrix"
    offer     = "netscaler-ma-service-agent"
    sku       = "netscaler-ma-service-agent"
    version   = "latest"
  }

  plan {
    name      = "netscaler-ma-service-agent"
    publisher = "citrix"
    product   = "netscaler-ma-service-agent"
  }


depends_on = [
    azurerm_network_interface.appinterface1,
   // azurerm_resource_group.cardirg,
    tls_private_key.linuxkey
   
  ]
  tags = {
    owner = "Kash"
  }
}
