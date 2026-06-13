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

| Concern | azurerm | azapi (this module) |
|---|---|---|
| Subscription scope | Storage account must be in provider subscription | Any storage account reachable by the caller |
| Provider blocks needed | One per subscription | None beyond a single `azapi {}` block |
| Auth | Shared key or ARM RBAC | Azure AD RBAC (`Storage Table Data Contributor`) |
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
