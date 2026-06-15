# Changelog

## [0.1.1](https://github.com/kewalaka/terraform-azapi-global-outputs/compare/v0.1.0...v0.1.1) (2026-06-15)


### Features

* initial module implementation ([a661716](https://github.com/kewalaka/terraform-azapi-global-outputs/commit/a661716576894436fd9dc7ca553e749c169927bc))


### Bug Fixes

* action versions ([de711ef](https://github.com/kewalaka/terraform-azapi-global-outputs/commit/de711eff824474f54cb7028f56d6e818e075f010))
* github versions and go module cache ([7d996f1](https://github.com/kewalaka/terraform-azapi-global-outputs/commit/7d996f149215dbdf4007da6ca29f94538afa1fc7))
* simplify terraform & fix destroy ([3bab8ad](https://github.com/kewalaka/terraform-azapi-global-outputs/commit/3bab8adfcce87eff9fc976b43baf62a0bc619210))
* simplify terraform & fix destroy ([2376780](https://github.com/kewalaka/terraform-azapi-global-outputs/commit/237678018d184d7e4fe22ef50f30f7d580122000))

## 0.1.0 (unreleased)

### Features

- Initial implementation: read/write cross-stack outputs via Azure Table Storage using `azapi_data_plane_resource`.
- Drop-in replacement for `terraform-azurerm-global-outputs` — same `storage_table_url` / `writes` / `reads` / `outputs` interface.
- No ARM subscription scope restriction: works across subscriptions with only a Storage Table Data Contributor RBAC assignment.
- Requires the `azapi` provider with data-plane Table Storage support (see [kewalaka/terraform-provider-azapi#add-table-storage-dataplane](https://github.com/kewalaka/terraform-provider-azapi/tree/kewalaka/add-table-storage-dataplane)).
