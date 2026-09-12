data "azapi_data_plane_resource" "read" {
  for_each = local.read_entries

  type      = "Microsoft.Storage/storageAccounts/tableServices/tables/entities@2026-04-06"
  parent_id = "${local.table_parent_id}(PartitionKey='${replace(each.value.pk, "'", "''")}',RowKey='${replace(each.value.rk, "'", "''")}')"
  headers   = local.table_entity_headers

  response_export_values = ["outputs"]
}
