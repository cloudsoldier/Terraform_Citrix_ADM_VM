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

subscription_id = "<xxxxxx-xxxxx-xxxxx-xxxx>"
tenant_id       =  "<xxxxxx-xxxxx-xxxxx-xxxx>"
}
