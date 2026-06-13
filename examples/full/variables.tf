variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "australiaeast"
}

variable "resource_group_name" {
  description = "Resource group to deploy into."
  type        = string
  default     = "rg-azapi-global-outputs-test"
}
