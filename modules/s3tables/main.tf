# --- reuse your existing data sources ---
data "aws_caller_identity" "this" {}
data "aws_region" "current" {}

# ---------- locals ----------
locals {
  account_id = data.aws_caller_identity.this.account_id
  region     = coalesce(var.aws_region, data.aws_region.current.id)

  table_bucket_names = {
    for i in range(var.start_index, var.start_index + var.bucket_count) :
    i => format("%s-lakehouse-table-bucket-%02d-%s", local.account_id, i, local.region)
  }

  lake_bucket_names = {
    for i in range(var.start_index, var.start_index + var.bucket_count) :
    i => format("%s-lakehouse-bucket-%02d-%s", local.account_id, i, local.region)
  }

  create_policy = var.attach_policy && length(var.policy_principals) > 0
}

# ---------- STANDARD S3 BUCKETS ----------
resource "aws_s3_bucket" "lake" {
  for_each      = local.lake_bucket_names
  bucket        = each.value
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_ownership_controls" "lake" {
  for_each = aws_s3_bucket.lake
  bucket   = each.value.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_public_access_block" "lake" {
  for_each                = aws_s3_bucket.lake
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "lake" {
  for_each = aws_s3_bucket.lake
  bucket   = each.value.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lake" {
  for_each = aws_s3_bucket.lake
  bucket   = each.value.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# ✅ FIXED: split bucket-level vs object-level actions correctly
resource "aws_s3_bucket_policy" "lake" {
  for_each = local.create_policy ? aws_s3_bucket.lake : {}
  bucket   = each.value.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Bucket-level actions (bucket ARN)
      {
        Sid       = "AllowBucketLevel"
        Effect    = "Allow"
        Principal = { AWS = var.policy_principals }
        Action    = [
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = [each.value.arn]
      },
      # Object-level actions (bucket/* ARN)
      {
        Sid       = "AllowObjectLevel"
        Effect    = "Allow"
        Principal = { AWS = var.policy_principals }
        Action    = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = ["${each.value.arn}/*"]
      }
    ]
  })

  depends_on = [aws_s3_bucket_ownership_controls.lake]
}

# ---------- S3 TABLES ----------
resource "aws_s3tables_table_bucket" "this" {
  for_each = local.table_bucket_names
  name     = each.value
}

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
      Resource  = [each.value.arn, "${each.value.arn}/*"]
    }]
  })
}