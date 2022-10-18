terraform {
required_version = ">= 1.0.0"
required_providers {
azurerm = {
source = "hashicorp/azurerm"
version = ">= 2.0" # Optional but recommended in production
}
}
}

provider "azurerm" {
features {}

subscription_id = "4f9fc577-70d6-4b0c-b0c9-3c7f24dae85f"
tenant_id       =  "b8b4c61c-f1ca-4aff-a0bd-9c6f01c3eca5"
}
