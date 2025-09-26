output "namespace_name" {
  value = aws_redshiftserverless_namespace.this.namespace_name
}

output "workgroup_name" {
  value = aws_redshiftserverless_workgroup.this.workgroup_name
}

output "endpoint" {
  value = local.endpoint
}

output "port" {
  value = local.port
}

output "jdbc_url" {
  value = local.jdbc_url
}

output "admin_secret_arn" {
  value = local.admin_secret_arn
}

output "workgroup_arn" {
  value = local.workgroup_arn
}

output "iam_role_arn" {
  value = local.role_arn
}

output "security_group_id" {
  value = local.security_group_id
}