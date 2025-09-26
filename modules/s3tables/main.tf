data "aws_caller_identity" "this" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.this.account_id
  region     = coalesce(var.aws_region, data.aws_region.current.id) # use .id on v6+

  # {Account-ID}-lakehouse-table-bucket-{##}-{region}
  table_bucket_names = {
    for i in range(var.start_index, var.start_index + var.bucket_count) :
    i => format("%s-lakehouse-table-bucket-%02d-%s", local.account_id, i, local.region)
  }

  create_policy = var.attach_policy && length(var.policy_principals) > 0
}

# S3 Tables table-buckets (NOT classic s3 buckets)
resource "aws_s3tables_table_bucket" "this" {
  for_each = local.table_bucket_names
  name     = each.value
}

# Optional: S3 Tables table-bucket policy (IAM layer)
# Correct fields for v6+: table_bucket_arn + resource_policy
resource "aws_s3tables_table_bucket_policy" "this" {
  for_each = local.create_policy ? aws_s3tables_table_bucket.this : {}

  table_bucket_arn = each.value.arn

  resource_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowS3TablesActionsForPrincipals",
      Effect    = "Allow",
      Principal = { AWS = var.policy_principals },
      Action    = "s3tables:*",
      Resource  = [
        each.value.arn,
        "${each.value.arn}/*"
      ]
    }]
  })
}