data "azurerm_virtual_network" "adcvnet" {
name                = "vnet-citrixgw-sbox"
resource_group_name = "rg-citrixgw-sbox"
}
output "virtual_network_id" {
value = data.azurerm_virtual_network.adcvnet.id
}

// Management subnet

data "azurerm_subnet" "snet-nsip-sbox" {
name                 = "snet-nsip-sbox"
virtual_network_name = "vnet-citrixgw-sbox"
resource_group_name  = "rg-citrixgw-sbox"
}

output "snet-nsip-sbox" {
value = data.azurerm_subnet.snet-nsip-sbox.id
}

//  Client subnet to access ADC via pip

data "azurerm_subnet" "snet-vip-sbox" {
name                 = "snet-vip-sbox"
virtual_network_name = "vnet-citrixgw-sbox"
resource_group_name  = "rg-citrixgw-sbox"
}

output "snet-vip-sbox_id" {
value = data.azurerm_subnet.snet-vip-sbox.id
}

// subnet for other servers

data "azurerm_subnet" "snet1-citrixgw-sbox" {
name                 = "snet1-citrixgw-sbox"
virtual_network_name = "vnet-citrixgw-sbox"
resource_group_name  = "rg-citrixgw-sbox"
}

output "snet1-citrixgw-sbox_id" {
value = data.azurerm_subnet.snet-vip-sbox.id
}

resource "azurerm_subnet_network_security_group_association" "management-subnet-association" {
subnet_id                 = data.azurerm_subnet.snet-nsip-sbox.id
network_security_group_id = azurerm_network_security_group.terraform-management-subnet-security-group.id
}

resource "azurerm_network_security_group" "terraform-management-subnet-security-group" {
name                = "terraform-management-subnet-security-group"
location            = var.location
resource_group_name = data.azurerm_resource_group.rg.name
}

///////////////////////////////

resource "azurerm_subnet_network_security_group_association" "client-subnet-association" {
subnet_id                 = data.azurerm_subnet.snet-vip-sbox.id
network_security_group_id = azurerm_network_security_group.terraform-client-subnet-security-group.id
}

resource "azurerm_network_security_group" "terraform-client-subnet-security-group" {
name                = "terraform-client-subnet-security-group"
location            = var.location
resource_group_name = data.azurerm_resource_group.rg.name
}

// Allow http and https from everywhere
resource "azurerm_network_security_rule" "terraform-allow-client-http-from-internet" {
name                        = "terraform-allow-client-http-from-internet"
priority                    = 1000
direction                   = "Inbound"
access                      = "Allow"
protocol                    = "Tcp"
source_port_range           = "*"
destination_port_ranges     = ["80", "443"]
source_address_prefix       = "*"
destination_address_prefix  = "*"
resource_group_name         = data.azurerm_resource_group.rg.name
network_security_group_name = azurerm_network_security_group.terraform-client-subnet-security-group.name
}

///////////////

resource "azurerm_subnet_network_security_group_association" "server-subnet-association" {
subnet_id                 = data.azurerm_subnet.snet1-citrixgw-sbox.id
network_security_group_id = azurerm_network_security_group.terraform-server-subnet-security-group.id
}

resource "azurerm_network_security_group" "terraform-server-subnet-security-group" {
name                = "terraform-server-subnet-security-group"
location            = var.location
resource_group_name = data.azurerm_resource_group.rg.name
}

// Next two rules: Allow server subnet to reply only inside its own subnet
resource "azurerm_network_security_rule" "terraform-server-allow-outbound" {
name                   = "terraform-server-allow-subnet-outbound"
priority               = 1000
direction              = "Outbound"
access                 = "Allow"
protocol               = "*"
source_port_range      = "*"
destination_port_range = "*"
source_address_prefix  = "*"
// destination_address_prefixes = [
//   azurerm_subnet.terraform-server-subnet.address_prefixes[0],
// ]
resource_group_name         = data.azurerm_resource_group.rg.name
network_security_group_name = azurerm_network_security_group.terraform-server-subnet-security-group.name
}

resource "azurerm_network_security_rule" "terraform-server-deny-all-outbound" {
name                        = "terraform-server-deny-all-outbound"
priority                    = 1010
direction                   = "Outbound"
access                      = "Deny"
protocol                    = "*"
source_port_range           = "*"
destination_port_range      = "*"
source_address_prefix       = "*"
destination_address_prefix  = "*"
resource_group_name         = data.azurerm_resource_group.rg.name
network_security_group_name = azurerm_network_security_group.terraform-server-subnet-security-group.name
}
