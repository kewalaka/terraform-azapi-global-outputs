locals {
  # Strip https:// to get the parent_id format expected by azapi:
  # "https://account.table.core.windows.net/tableName" -> "account.table.core.windows.net/tableName"
  table_parent_id = trimprefix(var.storage_table_url, "https://")

  # Flatten reads into "pk/rk" => { pk, rk, keys } for for_each iteration.
  read_entries = {
    for entry in flatten([
      for pk, rk_map in var.reads : [
        for rk, keys in rk_map : {
          id   = "${pk}/${rk}"
          pk   = pk
          rk   = rk
          keys = keys
        }
      ]
    ]) : entry.id => entry
  }

  # Decode each entity's outputs blob once; fall back to {} on missing/invalid JSON.
  read_outputs = {
    for id, entity in data.azapi_data_plane_resource.read :
    id => try(jsondecode(entity.output.outputs), {})
  }
}
