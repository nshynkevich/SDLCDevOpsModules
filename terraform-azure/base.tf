terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.20.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "putyouro-wnsu-bscr-ipti-onidhere1111"
}

resource "azurerm_resource_group" "resourcegroup" {
  name     = "my_mentoring_rg"
  location = "West Europe"

}

