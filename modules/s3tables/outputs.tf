# S3 Tables
output "table_bucket_names" {
  description = "S3 Tables table-bucket names created (ordered)."
  value       = var.create_tables_buckets ? [for i in sort(keys(local.table_bucket_names)) : local.table_bucket_names[i]] : []
}

output "table_bucket_arns" {
  description = "S3 Tables table-bucket ARNs created (ordered)."
  value       = var.create_tables_buckets ? [for b in aws_s3tables_table_bucket.this : b.arn] : []
}

output "map_names_to_arns" {
  description = "Map of S3 Tables table-bucket name => ARN."
  value       = var.create_tables_buckets ? { for _, b in aws_s3tables_table_bucket.this : b.name => b.arn } : {}
}

# Classic S3
output "lake_bucket_names" {
  description = "Classic S3 bucket names created (ordered)."
  value       = var.create_classic_buckets ? [for i in sort(keys(local.lake_bucket_names)) : local.lake_bucket_names[i]] : []
}

output "lake_bucket_arns" {
  description = "Classic S3 bucket ARNs created (ordered)."
  value       = var.create_classic_buckets ? [for b in aws_s3_bucket.lake : b.arn] : []
}

output "map_lake_names_to_arns" {
  description = "Map of classic S3 bucket name => ARN."
  value       = var.create_classic_buckets ? { for _, b in aws_s3_bucket.lake : b.bucket => b.arn } : {}
}