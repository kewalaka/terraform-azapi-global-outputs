terraform {
  required_version = ">= 1.13"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.10"
    }
  }
}
