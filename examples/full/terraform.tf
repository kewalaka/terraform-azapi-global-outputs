# When using the locally built provider, Terraform reads from dev_overrides
# in ~/.terraformrc and skips the registry for Azure/azapi.
# See ../../DEV.md for setup instructions.
terraform {
  required_version = ">= 1.13"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.10"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.14"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}
