
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


