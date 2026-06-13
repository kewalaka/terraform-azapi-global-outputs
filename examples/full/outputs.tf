output "hub_vnet_aue" {
  description = "Hub VNet ID for Australia East (specific key read)."
  value       = module.read_hub.outputs["connectivity-hub"]["australiaeast"]["hub_vnet_id"]
}

output "all_nzn_outputs" {
  description = "All hub outputs for New Zealand North (wildcard read)."
  value       = module.read_hub.outputs["connectivity-hub"]["newzealandnorth"]
}
