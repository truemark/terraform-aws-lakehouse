output "table_bucket_names" {
  description = "S3 Tables table-bucket names created (ordered)."
  value       = [for i in sort(keys(local.table_bucket_names)) : local.table_bucket_names[i]]
}

output "table_bucket_arns" {
  description = "S3 Tables table-bucket ARNs created (ordered)."
  value       = [for b in aws_s3tables_table_bucket.this : b.arn]
}

output "map_names_to_arns" {
  description = "Map of table-bucket name => ARN."
  value       = { for _, b in aws_s3tables_table_bucket.this : b.name => b.arn }
}