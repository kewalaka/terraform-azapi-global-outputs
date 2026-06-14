output "outputs" {
  description = <<DESCRIPTION
A 3-level nested map of read outputs: outputs[partition_key][row_key][output_key].

Example access:
  module.global_outputs.outputs["alz-platform-connectivity-hub"]["australiaeast"].hub_virtual_network_id
DESCRIPTION
  value = {
    for pk, rk_map in var.reads : pk => {
      for rk, keys in rk_map : rk => {
        for k in(
          length(keys) > 0
          ? keys
          : keys(local.read_outputs["${pk}/${rk}"])
        ) : k => try(local.read_outputs["${pk}/${rk}"][k], null)
      }
    }
  }
}
