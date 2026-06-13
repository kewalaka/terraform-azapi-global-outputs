resource "azapi_data_plane_resource" "write" {
  count = var.writes != null ? 1 : 0

  type      = "Microsoft.Storage/storageAccounts/tableServices/tables/entities@2026-04-06"
  parent_id = local.table_parent_id

  identifiers = {
    partitionKey = var.writes.partition_key
    rowKey       = var.writes.row_key
  }

  # Outputs are stored as a single JSON-encoded blob so that the entity
  # remains a flat string map while still supporting arbitrary output types.
  body = {
    outputs = jsonencode(var.writes.outputs)
  }
}
