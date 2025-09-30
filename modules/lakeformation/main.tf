############################################
# lakeformation-init/main.tf
# - Sets Lake Formation admins exactly as provided
# - Seeds optional LF tags
############################################

data "aws_caller_identity" "this" {}

locals {
  catalog_id = var.catalog_id != null ? var.catalog_id : data.aws_caller_identity.this.account_id
}

# Lake Formation admins (must be stable IAM role/user ARNs, not STS session ARNs)
resource "aws_lakeformation_data_lake_settings" "this" {
  catalog_id = local.catalog_id
  admins     = var.data_lake_admins

  lifecycle {
    precondition {
      condition     = length(var.data_lake_admins) > 0
      error_message = "You must provide at least one IAM principal ARN in data_lake_admins."
    }
  }
}

# Optional starter LF-Tags
resource "aws_lakeformation_lf_tag" "defaults" {
  for_each = var.create_default_lf_tags ? {
    environment = ["dev", "test", "prod"]
    pii         = ["none", "contains"]
  } : {}

  catalog_id = local.catalog_id
  key        = each.key
  values     = each.value
}

# Additional LF-Tags
resource "aws_lakeformation_lf_tag" "extra" {
  for_each = var.lf_tags

  catalog_id = local.catalog_id
  key        = each.key
  values     = each.value.values
}