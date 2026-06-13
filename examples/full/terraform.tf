# When using the locally built provider, Terraform reads from dev_overrides
# in ~/.terraformrc and skips the registry for Azure/azapi.
# See ../../DEV.md for setup instructions.
terraform {
  required_version = ">= 1.9"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}
