data "aws_caller_identity" "this" {}

locals {
  catalog_id = var.catalog_id != null ? var.catalog_id : data.aws_caller_identity.this.account_id
}

# Lake Formation: set admins (provider v6 expects list(string))
resource "aws_lakeformation_data_lake_settings" "this" {
  catalog_id = local.catalog_id
  admins     = var.data_lake_admins
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