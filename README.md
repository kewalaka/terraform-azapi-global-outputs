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

## Inputs

| Name | Description | Type | Required |
|---|---|---|---|
| `storage_table_url` | Full HTTPS URL of the Table Storage table | `string` | yes |
| `writes` | Entity to write (`partition_key`, `row_key`, `outputs`) | `object` | no |
| `reads` | Map of `{ pk => { rk => [keys] } }` to read | `map(map(list(string)))` | no |

## Outputs

| Name | Description |
|---|---|
| `outputs` | `outputs[partition_key][row_key][output_key]` — nested map of read results |

---

## Examples

- [`examples/full/`](./examples/full/) — creates a storage account, table, RBAC assignment, writes two entities, and reads them back.

---

## See also

- [DEV.md](./DEV.md) — building and using the provider locally
- [terraform-azurerm-global-outputs](https://github.com/Datacom-Public-Cloud-IaC/terraform-azurerm-global-outputs) — the azurerm original
