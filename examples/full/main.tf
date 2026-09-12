data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  upper   = false
  special = false
  numeric = true
}

locals {
  resource_group_name  = "${var.resource_group_name}-${random_string.suffix.result}"
  storage_account_name = "stazapigot${random_string.suffix.result}"
}

# Create the resource group via ARM control plane.
resource "azapi_resource" "resource_group" {
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
  name     = local.resource_group_name
  location = var.location
}

# Create the storage account via ARM control plane and disable shared keys.
resource "azapi_resource" "storage_account" {
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  name      = local.storage_account_name
  parent_id = azapi_resource.resource_group.id
  location  = var.location

  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_LRS"
    }
    properties = {
      allowSharedKeyAccess = false
    }
  }
}

resource "random_uuid" "table_contributor_role_assignment" {}

# Grant the current caller data-plane access for entity read/write operations.
resource "azapi_resource" "table_contributor" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = random_uuid.table_contributor_role_assignment.result
  parent_id = azapi_resource.storage_account.id

  body = {
    properties = {
      roleDefinitionId = "${data.azapi_client_config.current.subscription_resource_id}/providers/Microsoft.Authorization/roleDefinitions/0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3"
      principalId      = data.azapi_client_config.current.object_id
    }
  }
}

# Create the table via ARM control plane — no shared keys needed.
resource "azapi_resource" "table" {
  type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2022-09-01"
  parent_id = "${azapi_resource.storage_account.id}/tableServices/default"
  name      = "globalOutputs"
  body = {
    properties = {
      signedIdentifiers = []
    }
  }
}

locals {
  table_url = "https://${local.storage_account_name}.table.core.windows.net/globalOutputs"
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

  depends_on = [azapi_resource.table, azapi_resource.table_contributor]
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

  depends_on = [azapi_resource.table, azapi_resource.table_contributor]
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
