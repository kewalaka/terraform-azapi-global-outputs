variable "storage_table_url" {
  description = "The full HTTPS URL of the Table Storage table used for global outputs, e.g. https://mystorageaccount.table.core.windows.net/globalOutputs"
  type        = string
}

variable "writes" {
  description = <<DESCRIPTION
Configuration for writing outputs to the global-outputs table.
One entity is created per module call (partition_key + row_key).

Example:
  writes = {
    partition_key = "alz-platform-connectivity-hub"
    row_key       = "australiaeast"
    outputs = {
      hub_virtual_network_id = module.hub_vnet.resource_id
      firewall_ip_address    = "10.0.0.4"
    }
  }
DESCRIPTION
  type = object({
    partition_key = string
    row_key       = string
    outputs       = any
  })
  default  = null
  nullable = true

  validation {
    condition     = var.writes == null || can(keys(var.writes.outputs))
    error_message = "writes.outputs must be a map."
  }
}

variable "reads" {
  description = <<DESCRIPTION
Configuration for reading outputs from the global-outputs table.
A map of PartitionKey to a map of RowKey to a list of output keys to read.

- Specific keys: { "pk" = { "rk" = ["key1", "key2"] } } returns only those keys.
- All keys:      { "pk" = { "rk" = [] } } returns all outputs for that entity.

Example:
  reads = {
    "alz-platform-connectivity-hub" = {
      "australiaeast"   = ["hub_virtual_network_id"]
      "newzealandnorth" = []
    }
  }
DESCRIPTION
  type        = map(map(list(string)))
  default     = {}
  nullable    = false
}
