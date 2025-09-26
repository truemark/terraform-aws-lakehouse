data "aws_caller_identity" "this" {}
data "aws_region"          "current" {}

locals {
  account_id = data.aws_caller_identity.this.account_id
  region     = data.aws_region.current.id

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
    execution_role = var.create_execution_role ? aws_iam_role.studio_exec[0].arn : null

    # Optional: studio settings (safe defaults)
    sharing_settings {
      notebook_output_option = "Allowed"
      s3_output_path         = length(var.raw_s3_bucket_arns) > 0 ? "${var.raw_s3_bucket_arns[0]}/studio-output/" : null
    }

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = "system"   # Studio-managed infra
      }
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = "ml.t3.medium"
        sage_maker_image_arn = null
      }
    }
  }

  dynamic "kms_key_id" {
    for_each = var.kms_key_id == null ? [] : [var.kms_key_id]
    content  = var.kms_key_id
  }

  tags = local.base_tags

  depends_on = [
    aws_security_group.studio_sg,
    aws_iam_role_policy_attachment.attach_data
  ]
}

# -------------------------------------------------------------------
# (4) Team user profiles
# -------------------------------------------------------------------
resource "aws_sagemaker_user_profile" "team" {
  for_each = { for u in var.user_profiles : u.name => u }

  domain_id      = aws_sagemaker_domain.this.id
  user_profile_name = each.value.name

  user_settings {
    execution_role = try(each.value.execution_role_arn, var.create_execution_role ? aws_iam_role.studio_exec[0].arn : null)

    # Allow per-user tags if provided
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
