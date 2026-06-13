# Changelog

## 0.1.0 (unreleased)

### Features

- Initial implementation: read/write cross-stack outputs via Azure Table Storage using `azapi_data_plane_resource`.
- Drop-in replacement for `terraform-azurerm-global-outputs` — same `storage_table_url` / `writes` / `reads` / `outputs` interface.
- No ARM subscription scope restriction: works across subscriptions with only a Storage Table Data Contributor RBAC assignment.
- Requires the `azapi` provider with data-plane Table Storage support (see [kewalaka/terraform-provider-azapi#add-table-storage-dataplane](https://github.com/kewalaka/terraform-provider-azapi/tree/kewalaka/add-table-storage-dataplane)).
