output "catalog_id" {
  description = "Glue Data Catalog ID used by the module."
  value       = local.catalog_id
}

output "lf_tags_created" {
  description = "LF-Tags created by this module (default + extra)."
  value       = concat(
    [for k, _ in aws_lakeformation_lf_tag.defaults : k],
    [for k, _ in aws_lakeformation_lf_tag.extra    : k]
  )
}

output "admins_effective" {
  description = "Effective Lake Formation admins configured (caller + extras)."
  value       = aws_lakeformation_data_lake_settings.this.admins
}