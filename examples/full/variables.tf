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

variable "principal_id" {
  description = <<-EOT
    Object ID of the principal granted Storage Table Data Contributor on the test
    storage account. Leave null to use the identity resolved by azapi_client_config.
    An explicit value is required for identities azapi cannot resolve, such as an
    OIDC service principal without Microsoft Graph access.
  EOT
  type        = string
  default     = null
}
