data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  upper   = false
  special = false
  numeric = true
}

resource "azurerm_resource_group" "example" {
  name     = "${var.resource_group_name}-${random_string.suffix.result}"
  location = var.location
}

resource "azurerm_storage_account" "example" {
  name                     = "stazapigot${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Grant the current caller data-plane access for entity read/write operations.
# RBAC propagation can take 1-2 minutes; entity writes will fail with 403 if
# applied too quickly. Re-run apply if this happens, or add a time_sleep after
# this resource.
resource "azurerm_role_assignment" "table_contributor" {
  scope                = azurerm_storage_account.example.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "time_sleep" "rbac_propagation" {
  depends_on      = [azurerm_role_assignment.table_contributor]
  create_duration = "90s"
}

# Create the table via ARM control plane — no shared keys needed.
resource "azapi_resource" "table" {
  type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2022-09-01"
  parent_id = "${azurerm_storage_account.example.id}/tableServices/default"
  name      = "globalOutputs"
  body = {
    properties = {
      signedIdentifiers = []
    }
  }
}

locals {
  table_url = "https://${azurerm_storage_account.example.name}.table.core.windows.net/globalOutputs"
}

# ---------------------------------------------------------------------------
# Writes: simulate two producing stacks storing connectivity hub outputs.
# ---------------------------------------------------------------------------

module "write_hub_aue" {
  source = "../../"

  storage_table_url = local.table_url
  writes = {
    partition_key = "connectivity-hub"
    row_key       = "australiaeast"
    outputs = {
      hub_vnet_id         = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub-aue"
      firewall_private_ip = "10.0.0.4"
    }
  }

  depends_on = [azapi_resource.table, time_sleep.rbac_propagation]
}

module "write_hub_nzn" {
  source = "../../"

  storage_table_url = local.table_url
  writes = {
    partition_key = "connectivity-hub"
    row_key       = "newzealandnorth"
    outputs = {
      hub_vnet_id         = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub-nzn"
      firewall_private_ip = "10.1.0.4"
    }
  }

  depends_on = [azapi_resource.table, time_sleep.rbac_propagation]
}

# ---------------------------------------------------------------------------
# Reads: simulate a consuming stack reading back selected outputs.
# ---------------------------------------------------------------------------

module "read_hub" {
  source = "../../"

  storage_table_url = local.table_url
  reads = {
    "connectivity-hub" = {
      "australiaeast"   = ["hub_vnet_id"] # read a specific key only
      "newzealandnorth" = []              # empty list = read all keys
    }
  }

  depends_on = [module.write_hub_aue, module.write_hub_nzn]
}
