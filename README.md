# terraform-azapi-global-outputs

A Terraform module for sharing outputs across stacks via Azure Table Storage,
using the [`azapi`](https://github.com/Azure/terraform-provider-azapi) provider's
data-plane resources — no `azurerm` provider needed, no subscription scope restrictions.

This is the azapi equivalent of
[terraform-azurerm-global-outputs](https://github.com/Datacom-Public-Cloud-IaC/terraform-azurerm-global-outputs).
It exposes the same variable interface (`storage_table_url`, `writes`, `reads`) and
the same output shape (`outputs[pk][rk][key]`), so the two modules are interchangeable
once the storage account exists.

> **Status:** requires the Table Storage data-plane feature from
> [`kewalaka/terraform-provider-azapi@kewalaka/add-table-storage-dataplane`](https://github.com/kewalaka/terraform-provider-azapi/tree/kewalaka/add-table-storage-dataplane).
> See [DEV.md](./DEV.md) for instructions on using a locally built provider.

---

## Why azapi instead of azurerm?

`azurerm_storage_table_entity` requires **shared key** (storage account access key)
authentication. Even though Azure Table Storage has supported Microsoft Entra ID
(Azure AD) authentication for data-plane operations since
[April 2022 (GA)](https://azure.microsoft.com/en-us/updates/?id=generally-available-azure-storage-table-access-using-azure-active-directory),
the `azurerm` provider has not been updated to use it.

The root cause was a specific ACL management operation that didn't support Entra auth
([azure-rest-api-specs#17485](https://github.com/Azure/azure-rest-api-specs/issues/17485)),
which blocked progress in the provider
([hashicorp/terraform-provider-azurerm#15083](https://github.com/hashicorp/terraform-provider-azurerm/issues/15083)).
That API issue was subsequently fixed ([Azure update 496287](https://azure.microsoft.com/en-us/updates/?id=496287))
but the azurerm provider still hasn't been updated as of mid-2025 — the issue remains open.

This module avoids the problem entirely by using `azapi_data_plane_resource`, which
calls the Table Storage REST API directly with a standard Azure AD bearer token
(OAuth 2.0 `https://storage.azure.com/.default` scope). No shared key is needed.

| Concern | azurerm | azapi (this module) |
|---|---|---|
| Auth model | Shared key only | Entra ID (Azure AD) RBAC |
| Shared key required? | Yes | No |
| Subscription scope | Storage account must be in provider subscription | Any storage account reachable by the caller |
| Provider blocks needed | One per subscription | None beyond a single `azapi {}` block |
| Terraform version | Any | >= 1.9 |

---

## Prerequisites

1. An Azure Storage account with Table Storage enabled.
2. The target table created (e.g. `globalOutputs`).
3. The Terraform caller identity assigned **`Storage Table Data Contributor`** on the storage account (or table level).

---

## Usage

### Write outputs (called from the producing stack)

```hcl
module "write_hub" {
  source = "github.com/kewalaka/terraform-azapi-global-outputs"

  storage_table_url = "https://${var.storage_account_name}.table.core.windows.net/globalOutputs"

  writes = {
    partition_key = "connectivity-hub"
    row_key       = "australiaeast"
    outputs = {
      hub_vnet_id         = azurerm_virtual_network.hub.id
      firewall_private_ip = azurerm_firewall.fw.ip_configuration[0].private_ip_address
    }
  }
}
```

### Read outputs (called from the consuming stack)

```hcl
module "global_outputs" {
  source = "github.com/kewalaka/terraform-azapi-global-outputs"

  storage_table_url = "https://${var.storage_account_name}.table.core.windows.net/globalOutputs"

  reads = {
    "connectivity-hub" = {
      "australiaeast"   = ["hub_vnet_id", "firewall_private_ip"]
      "newzealandnorth" = []  # empty list = read all keys
    }
  }
}

resource "azurerm_virtual_network_peering" "to_hub" {
  remote_virtual_network_id = module.global_outputs.outputs["connectivity-hub"]["australiaeast"]["hub_vnet_id"]
  # ...
}
```

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | >= 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_data_plane_resource.write](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/data_plane_resource) | resource |
| [azapi_data_plane_resource.read](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/data_plane_resource) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_storage_table_url"></a> [storage\_table\_url](#input\_storage\_table\_url) | The full HTTPS URL of the Table Storage table used for global outputs, e.g. https://mystorageaccount.table.core.windows.net/globalOutputs | `string` | n/a | yes |
| <a name="input_reads"></a> [reads](#input\_reads) | Configuration for reading outputs from the global-outputs table.<br/>A map of PartitionKey to a map of RowKey to a list of output keys to read.<br/><br/>- Specific keys: { "pk" = { "rk" = ["key1", "key2"] } } returns only those keys.<br/>- All keys:      { "pk" = { "rk" = [] } } returns all outputs for that entity.<br/><br/>Example:<br/>  reads = {<br/>    "alz-platform-connectivity-hub" = {<br/>      "australiaeast"   = ["hub\_virtual\_network\_id"]<br/>      "newzealandnorth" = []<br/>    }<br/>  } | `map(map(list(string)))` | `{}` | no |
| <a name="input_writes"></a> [writes](#input\_writes) | Configuration for writing outputs to the global-outputs table.<br/>One entity is created per module call (partition\_key + row\_key).<br/><br/>Example:<br/>  writes = {<br/>    partition\_key = "alz-platform-connectivity-hub"<br/>    row\_key       = "australiaeast"<br/>    outputs = {<br/>      hub\_virtual\_network\_id = module.hub\_vnet.resource\_id<br/>      firewall\_ip\_address    = "10.0.0.4"<br/>    }<br/>  } | <pre>object({<br/>    partition_key = string<br/>    row_key       = string<br/>    outputs       = any<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_outputs"></a> [outputs](#output\_outputs) | A 3-level nested map of read outputs: outputs[partition\_key][row\_key][output\_key].<br/><br/>Example access:<br/>  module.global\_outputs.outputs["alz-platform-connectivity-hub"]["australiaeast"].hub\_virtual\_network\_id |
<!-- END_TF_DOCS -->

---

## Examples

- [`examples/full/`](./examples/full/) — creates a storage account, table, RBAC assignment, writes two entities, and reads them back.

---

## See also

- [DEV.md](./DEV.md) — building and using the provider locally
- [terraform-azurerm-global-outputs](https://github.com/Datacom-Public-Cloud-IaC/terraform-azurerm-global-outputs) — the azurerm original
