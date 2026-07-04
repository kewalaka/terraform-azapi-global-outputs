# Full example

Creates a storage account, table, and RBAC assignment from scratch,
then exercises both `writes` and `reads` in the same apply.

## What it does

1. Creates a resource group and storage account via `azapi_resource` (with shared key auth disabled)
2. Assigns **Storage Table Data Contributor** to the current caller via `azapi_resource`
3. Creates the `globalOutputs` table via `azapi_resource` (ARM control plane)
4. Writes two entities (simulating two producing stacks), using AzAPI customized retry for transient authorization errors
5. Reads back one entity with a specific key filter and one with all keys

## Run

See [../../DEV.md](../../DEV.md) for provider setup, then:

```bash
export AZURE_CONFIG_DIR=$(mktemp -d)
az login
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"

cd examples/full
terraform apply
```

## Expected outputs

```
hub_vnet_aue = "/subscriptions/00000000.../vnet-hub-aue"
all_nzn_outputs = {
  firewall_private_ip = "10.1.0.4"
  hub_vnet_id         = "/subscriptions/00000000.../vnet-hub-nzn"
}
```

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 2.10 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | >= 2.10 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_read_hub"></a> [read\_hub](#module\_read\_hub) | ../../ | n/a |
| <a name="module_write_hub_aue"></a> [write\_hub\_aue](#module\_write\_hub\_aue) | ../../ | n/a |
| <a name="module_write_hub_nzn"></a> [write\_hub\_nzn](#module\_write\_hub\_nzn) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.resource_group](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.storage_account](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.table](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.table_contributor](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_uuid.table_contributor_role_assignment](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [azapi_client_config.current](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region for all resources. | `string` | `"australiaeast"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group to deploy into. | `string` | `"rg-azapi-global-outputs-test"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_all_nzn_outputs"></a> [all\_nzn\_outputs](#output\_all\_nzn\_outputs) | All hub outputs for New Zealand North (wildcard read). |
| <a name="output_hub_vnet_aue"></a> [hub\_vnet\_aue](#output\_hub\_vnet\_aue) | Hub VNet ID for Australia East (specific key read). |
<!-- END_TF_DOCS -->
