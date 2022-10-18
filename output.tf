/*
output "public_nsip" {
value = azurerm_public_ip.terraform-adc-management-public-ip.ip_address
}
*/
output "private_nsip" {
value = azurerm_network_interface.terraform-adc-management-interface.private_ip_address
}

output "public_vip" {
value = azurerm_public_ip.terraform-adc-client-public-ip.ip_address
}

output "private_vip" {
value = azurerm_network_interface.terraform-adc-client-interface.private_ip_address
}

/*
output "server_subnet_id" {
value = azurerm_subnet.terraform-server-subnet.id
}

output "management_subnet_id" {
value = azurerm_subnet.terraform-management-subnet.id
}
*/

/*
output "bastion_public_ip" {
value = azurerm_public_ip.terraform-ubuntu-public-ip.ip_address
}
*/

---

resourcegroup.tf

data "azurerm_resource_group" "rg" {
name = "rg-citrixgw-sbox"
}

---

terraform.tfvars

# Uncomment and change values as needed

terraform-ubuntu-machine_name       = "CitixADC"
resource_group_name                 = "citrixadc-terra-rg"
location                            = "uksouth"
virtual_network_address_space       = "10.0.0.0/24"
management_subnet_address_prefix    = "10.0.0.176/28"
client_subnet_address_prefix        = "10.0.0.0/26"
server_subnet_address_prefix        = "10.0.0.160/28"
adc_admin_username                  = "azureuser"
adc_admin_password                  = "Password@123456"
ubuntu_vm_size                      = "Standard_DS3_v2"
controlling_subnet                  = "10.0.0.190/32"
adc_vm_size                         = "Standard_DS3_v2"

---

variables.tf

variable "terraform-ubuntu-machine_name" {
description = "Name for the resource group that will contain all created resources"
default     = "terraform-resource-group"
}

variable "resource_group_name" {
description = "Name for the resource group that will contain all created resources"
default     = "terraform-resource-group"
}

variable "location" {
description = "Azure location where all resources will be created"
}

variable "virtual_network_address_space" {
description = "Address space for the virtual network."
}

variable "management_subnet_address_prefix" {
description = "The address prefix that will be used for the management subnet. Must be contained inside the VNet address space"
}

variable "client_subnet_address_prefix" {
description = "The address prefix that will be used for the client subnet. Must be contained inside the VNet address space"
}

variable "server_subnet_address_prefix" {
description = "The address prefix that will be used for the server subnet. Must be contained inside the VNet address space"
}

variable "adc_admin_username" {
description = "User name for the Citrix ADC admin user."
default     = "nsroot"
}

variable "adc_admin_password" {
description = "Password for the Citrix ADC admin user. Must be sufficiently complex to pass azurerm provider checks."
}

variable "ssh_public_key_file" {
description = "Public key file for accessing the ubuntu bastion machine."
default     = "~/.ssh/id_rsa.pub"
}

variable "ubuntu_vm_size" {
description = "Size for the ubuntu machine."
default     = "Standard_A1_v2"
}

variable "controlling_subnet" {
#description = "The CIDR block of the machines that will be allowed access to the management subnet."
}

variable "adc_vm_size" {
description = "Size for the ADC machine. Must allow for 3 NICs."
default     = "Standard_F8s_v2"
}
