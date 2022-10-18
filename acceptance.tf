resource "azurerm_marketplace_agreement" "CitrixADC" {
publisher = "citrix"
offer     = "netscalervpx-130"
plan      =  "netscalervpxexpress"
}
