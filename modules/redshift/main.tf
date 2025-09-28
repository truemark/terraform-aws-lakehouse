# -----------------------
# IAM Role for Redshift
# -----------------------
resource "aws_iam_role" "redshift_serverless_role" {
  name        = var.iam_role_name
  description = "IAM role for Redshift Serverless to access AWS services"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "redshift.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "redshift_full_access" {
  role       = aws_iam_role.redshift_serverless_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftAllCommandsFullAccess"
}

# -----------------------
# Admin password handling
# -----------------------
resource "random_password" "admin" {
  count   = var.admin_password == null ? 1 : 0
  length  = 16
  special = false
}

locals {
  effective_admin_password = coalesce(
    var.admin_password,
    try(random_password.admin[0].result, null)
  )
}

# -----------------------
# Secrets Manager (optional create)
# -----------------------
resource "aws_secretsmanager_secret" "redshift" {
  count = var.existing_admin_secret_arn == null ? 1 : 0
  name  = "${var.namespace_name}-admin-secret"
  tags  = var.tags
}

resource "aws_secretsmanager_secret_version" "redshift" {
  count     = var.existing_admin_secret_arn == null ? 1 : 0
  secret_id = aws_secretsmanager_secret.redshift[0].id
  secret_string = jsonencode({
    username = var.admin_user
    password = local.effective_admin_password
  })
}

locals {
  admin_secret_arn = coalesce(
    var.existing_admin_secret_arn,
    try(aws_secretsmanager_secret.redshift[0].arn, null)
  )
}

# -----------------------
# Namespace
# -----------------------
resource "aws_redshiftserverless_namespace" "this" {
  namespace_name      = var.namespace_name
  db_name             = var.database_name
  admin_username      = var.admin_user
  admin_user_password = local.effective_admin_password
  iam_roles           = [aws_iam_role.redshift_serverless_role.arn]

  tags = var.tags
}

# -----------------------
# Security Group (optional create)
# -----------------------
resource "aws_security_group" "this" {
  count       = var.existing_security_group_id == null ? 1 : 0
  name        = "${var.namespace_name}-sg"
  description = "Allow Redshift Serverless access"
  vpc_id      = var.vpc_id
  tags        = var.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Ingress rules if we created the SG
resource "aws_security_group_rule" "ingress" {
  for_each = var.existing_security_group_id == null ? toset(var.ingress_cidrs) : toset([])

  type              = "ingress"
  security_group_id = aws_security_group.this[0].id
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = [each.key]
  description       = "Allow Redshift access from ${each.key}"
}

locals {
  security_group_id = coalesce(
    var.existing_security_group_id,
    try(aws_security_group.this[0].id, null)
  )
}

# -----------------------
# Workgroup
# -----------------------
resource "aws_redshiftserverless_workgroup" "this" {
  workgroup_name       = var.workgroup_name
  namespace_name       = aws_redshiftserverless_namespace.this.namespace_name
  base_capacity        = var.base_capacity
  publicly_accessible  = var.publicly_accessible
  enhanced_vpc_routing = var.enhanced_vpc_routing
  security_group_ids   = [local.security_group_id]
  subnet_ids           = var.subnet_ids
  tags                 = var.tags
}

# -----------------------
# Helpful computed strings
# -----------------------
locals {
  # Workgroup endpoint is a list with one object; extract safely
  endpoint_obj     = try(aws_redshiftserverless_workgroup.this.endpoint[0], null)
  endpoint_address = try(local.endpoint_obj.address, null)
  endpoint_port    = try(local.endpoint_obj.port, var.port)

  # Single-line ternary avoids parse errors
  jdbc_url = local.endpoint_address != null ? format("jdbc:redshift://%s:%s/%s", local.endpoint_address, local.endpoint_port, var.database_name) : null

  workgroup_arn = aws_redshiftserverless_workgroup.this.arn
  role_arn      = aws_iam_role.redshift_serverless_role.arn
}