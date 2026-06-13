# Using a locally built provider

This module requires the Table Storage data-plane feature from the
[`kewalaka/add-table-storage-dataplane`](https://github.com/kewalaka/terraform-provider-azapi/tree/kewalaka/add-table-storage-dataplane)
branch. That feature is not yet in the upstream registry.

---

## 1. Clone and build the provider

```bash
git clone https://github.com/kewalaka/terraform-provider-azapi.git
cd terraform-provider-azapi
git checkout kewalaka/add-table-storage-dataplane

# Build the binary into a dedicated local provider directory
mkdir -p ~/terraform-providers
go build -o ~/terraform-providers/terraform-provider-azapi .
```

On Windows substitute `~/terraform-providers` with `%USERPROFILE%\terraform-providers`
and add `.exe` to the binary name.

---

## 2. Configure Terraform dev overrides

Create or edit `~/.terraformrc` (Windows: `%APPDATA%\terraform.rc`):

```hcl
provider_installation {
  dev_overrides {
    "Azure/azapi" = "/Users/you/terraform-providers"
  }
  # Fall through to the public registry for all other providers
  direct {}
}
```

With this in place Terraform skips the registry for `Azure/azapi` and loads the
binary directly. You will see a warning about dev overrides — this is expected.

> **Do not** run `terraform init` when dev_overrides is active for azapi — Terraform
> will warn and skip the lock file for that provider, which is fine. If you do run
> `init`, it will succeed but the lock file entry for azapi will be absent or stale.

---

## 3. Authenticate

Use a temporary Azure CLI profile to avoid overwriting your default config:

```bash
export AZURE_CONFIG_DIR=$(mktemp -d)
az login
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
```

The identity needs:
- **`Contributor`** on the resource group (to create the storage account and RBAC assignment)
- **`Storage Table Data Contributor`** on the storage account (for data-plane entity operations)

The `examples/full` example creates the RBAC assignment, so `Contributor` on the
resource group is sufficient to bootstrap from scratch.

---

## 4. Run the full example

```bash
cd examples/full
terraform apply
```

The example creates its own resource group, storage account, table, and RBAC assignment,
then writes and reads two entities. See [`examples/full/README.md`](./examples/full/README.md)
for expected outputs.

---

## 5. Tear down

```bash
terraform destroy
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Provider "Azure/azapi" not found` | Binary missing from dev_overrides path | Check `~/terraform-providers/terraform-provider-azapi` exists and is executable (`chmod +x`) |
| `403 Forbidden` on entity operations | Missing RBAC assignment | Ensure `Storage Table Data Contributor` is assigned; wait 1–2 min for propagation |
| `400 Bad Request` mentioning `x-ms-version` | Old provider binary without Table Storage support | Rebuild from `kewalaka/add-table-storage-dataplane` branch |
| `404 Not Found` on entity read | Table does not exist yet | Confirm `depends_on = [azapi_data_plane_resource.table]` is present |
| `403` on table create despite correct RBAC | RBAC propagation delay | Add `time_sleep` resource after RBAC assignment, or re-run `apply` |

---

## Setting up the GitHub Actions integration test

The `integration.yml` workflow needs three things before it can run.

### 1. Repository variables (Settings → Secrets and variables → Actions → Variables)

| Variable | Example | Notes |
|---|---|---|
| `ARM_CLIENT_ID` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | Client ID of the App Registration or managed identity |
| `ARM_TENANT_ID` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | Entra ID tenant |
| `ARM_SUBSCRIPTION_ID` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | Target subscription |

### 2. Federated identity credentials (OIDC)

In the App Registration → Certificates & secrets → Federated credentials, add one entry **per trigger**:

| Scenario | Subject claim | Audience |
|---|---|---|
| Push to main (plan) | `repo:kewalaka/terraform-azapi-global-outputs:ref:refs/heads/main` | `api://AzureADTokenExchange` |
| Environment gate (apply) | `repo:kewalaka/terraform-azapi-global-outputs:environment:integration` | `api://AzureADTokenExchange` |
| Pull request (plan) | `repo:kewalaka/terraform-azapi-global-outputs:pull_request` | `api://AzureADTokenExchange` |

The App Registration needs **`Storage Table Data Contributor`** on the storage account and **Contributor** (or a custom role) on the subscription/resource group used by the example.

### 3. GitHub Environment (Settings → Environments → New environment)

Create an environment named **`integration`** and add at least one required reviewer.  
When a push lands on `main`, the plan job runs immediately; the apply job waits until a reviewer approves it in the GitHub Actions UI.

