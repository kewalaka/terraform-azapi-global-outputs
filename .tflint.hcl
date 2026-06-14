# Run `tflint --init` to download the plugin before first use.
# In CI, GITHUB_TOKEN should be set to avoid rate limiting on plugin downloads.

plugin "terraform" {
  enabled = true
  version = "0.10.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

config {
  # Don't follow module calls — remote providers are not initialised in CI.
  call_module_type = "none"
}

rule "terraform_standard_module_structure" {
  enabled = false
}