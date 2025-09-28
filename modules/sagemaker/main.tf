data "aws_caller_identity" "this" {}
data "aws_region"          "current" {}

locals {
  account_id = data.aws_caller_identity.this.account_id
  region     = data.aws_region.current.id

  # First raw bucket ARN if provided, else null
  first_raw_bucket_arn = length(var.raw_s3_bucket_arns) > 0 ? var.raw_s3_bucket_arns[0] : null

  # Convert ARN (arn:aws:s3:::bucket) -> URI (s3://bucket) and build output path
  s3_output_path = local.first_raw_bucket_arn != null ? format("%s/studio-output/", replace(local.first_raw_bucket_arn, "arn:aws:s3:::", "s3://")) : null

  # Base tags
  base_tags = merge(
    {
      Project = "lakehouse"
      Module  = "sagemaker-studio-unified"
    },
    var.tags
  )
}

# -------------------------------------------------------------------
# (1) IAM execution role (shared)
# -------------------------------------------------------------------
data "aws_iam_policy_document" "assume_sagemaker" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "studio_exec" {
  count              = var.create_execution_role ? 1 : 0
  name               = var.execution_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_sagemaker.json
  tags               = local.base_tags
}

# Allow basic SageMaker actions commonly required within Studio
data "aws_iam_policy_document" "studio_base" {
  statement {
    sid     = "SageMakerBasic"
    effect  = "Allow"
    actions = [
      "sagemaker:*Notebook*",
      "sagemaker:List*",
      "sagemaker:Describe*",
      "sagemaker:CreatePresigned*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }

  # S3 classic (raw buckets)
  dynamic "statement" {
    for_each = length(var.raw_s3_bucket_arns) > 0 ? [1] : []
    content {
      sid    = "S3RawDataAccess"
      effect = "Allow"
      actions = [
        "s3:GetObject","s3:PutObject","s3:DeleteObject",
        "s3:ListBucket","s3:GetBucketLocation"
      ]
      resources = concat(
        var.raw_s3_bucket_arns,
        [for b in var.raw_s3_bucket_arns : "${b}/*"]
      )
    }
  }

  # S3 Tables (table-buckets) – IAM access to API; LF still governs fine-grained data perms
  dynamic "statement" {
    for_each = length(var.s3tables_table_bucket_arns) > 0 ? [1] : []
    content {
      sid     = "S3TablesAPIAccess"
      effect  = "Allow"
      actions = ["s3tables:*"]
      resources = concat(
        var.s3tables_table_bucket_arns,
        [for a in var.s3tables_table_bucket_arns : "${a}/*"]
      )
    }
  }
}

resource "aws_iam_policy" "studio_data_access" {
  count       = var.create_execution_role && var.attach_data_access_policy ? 1 : 0
  name        = "${var.execution_role_name}-DataAccess"
  policy      = data.aws_iam_policy_document.studio_base.json
  description = "Studio execution role access to S3 raw and S3 Tables (API)."
  tags        = local.base_tags
}

resource "aws_iam_role_policy_attachment" "attach_data" {
  count      = var.create_execution_role && var.attach_data_access_policy ? 1 : 0
  role       = aws_iam_role.studio_exec[0].name
  policy_arn = aws_iam_policy.studio_data_access[0].arn
}

# -------------------------------------------------------------------
# (2) Security group for Studio domain (egress only)
# -------------------------------------------------------------------
resource "aws_security_group" "studio_sg" {
  name        = "${var.domain_name}-studio-sg"
  description = "Security group for SageMaker Studio domain"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.base_tags
}

# -------------------------------------------------------------------
# (3) SageMaker Studio Domain (IAM mode, VPC-only)
# -------------------------------------------------------------------
resource "aws_sagemaker_domain" "this" {
  domain_name = var.domain_name
  auth_mode   = "IAM"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  app_network_access_type = "VpcOnly" # private Studio

  domain_settings {
    security_group_ids = [aws_security_group.studio_sg.id]
  }

  default_user_settings {
    # Avoid indexing a non-existent resource when create_execution_role = false
    execution_role = length(aws_iam_role.studio_exec) > 0 ? aws_iam_role.studio_exec[0].arn : null

    # Optional: studio settings (safe defaults)
    sharing_settings {
      notebook_output_option = "Allowed"
      s3_output_path         = local.s3_output_path
    }

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = "system"   # Studio-managed infra
      }
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type       = "ml.t3.medium"
        sagemaker_image_arn = null
      }
    }
  }

  # kms_key_id is a simple argument (may be null)
  kms_key_id = var.kms_key_id

  tags = local.base_tags

  depends_on = [
    aws_security_group.studio_sg
  ]
}

# -------------------------------------------------------------------
# (4) Team user profiles
# -------------------------------------------------------------------
resource "aws_sagemaker_user_profile" "team" {
  for_each = { for u in var.user_profiles : u.name => u }

  domain_id         = aws_sagemaker_domain.this.id
  user_profile_name = each.value.name

  user_settings {
    # Prefer a per-user override; else fall back to the shared role if it exists
    execution_role = coalesce(
      try(each.value.execution_role_arn, null),
      length(aws_iam_role.studio_exec) > 0 ? aws_iam_role.studio_exec[0].arn : null
    )

    security_groups = [aws_security_group.studio_sg.id]

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = "system"
      }
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = "ml.t3.medium"
      }
    }
  }

  tags = merge(local.base_tags, try(each.value.tags, {}))
}