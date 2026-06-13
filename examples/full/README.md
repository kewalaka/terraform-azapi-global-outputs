# Full example

Creates a storage account, table, and RBAC assignment from scratch,
then exercises both `writes` and `reads` in the same apply.

## What it does

1. Creates a resource group and storage account
2. Assigns **Storage Table Data Contributor** to the current caller
3. Creates the `globalOutputs` table via `azapi_data_plane_resource`
4. Writes two entities (simulating two producing stacks)
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
