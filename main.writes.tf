resource "azapi_data_plane_resource" "write" {
  count = var.writes != null ? 1 : 0

  type           = "Microsoft.Storage/storageAccounts/tableServices/tables/entities@2026-04-06"
  parent_id      = "${local.table_parent_id}(PartitionKey='${replace(var.writes.partition_key, "'", "''")}',RowKey='${replace(var.writes.row_key, "'", "''")}')"
  create_headers = local.table_entity_headers
  read_headers   = local.table_entity_headers
  update_headers = local.table_entity_headers
  delete_headers = merge(local.table_entity_headers, { "If-Match" = "*" })

  # Role assignment propagation in Storage data plane is eventually consistent.
  # Retry authorization failures so callers do not need artificial sleeps.
  retry = {
    error_message_regex = [
      "(?i)AuthorizationPermissionMismatch",
      "(?i)not authorized",
      "(?i)forbidden",
      "(?i)authorization",
    ]
    interval_seconds     = 10
    max_interval_seconds = 120
  }

  # Outputs are stored as a single JSON-encoded blob so that the entity
  # remains a flat string map while still supporting arbitrary output types.
  body = {
    outputs = jsonencode(var.writes.outputs)
  }
}
