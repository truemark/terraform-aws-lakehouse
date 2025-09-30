output "namespace_name" {
  description = "Redshift Serverless namespace name"
  value       = aws_redshiftserverless_namespace.this.namespace_name
}

output "workgroup_name" {
  description = "Redshift Serverless workgroup name"
  value       = aws_redshiftserverless_workgroup.this.workgroup_name
}

output "endpoint" {
  description = "Redshift Serverless endpoint DNS name"
  value       = local.endpoint_address
}

output "port" {
  description = "Redshift Serverless endpoint port"
  value       = local.endpoint_port
}

output "jdbc_url" {
  description = "Convenience JDBC URL for connecting to the default database"
  value       = local.jdbc_url
}

output "admin_secret_arn" {
  description = "Secrets Manager ARN storing admin username/password"
  value       = local.admin_secret_arn
}

output "workgroup_arn" {
  description = "ARN of the Redshift Serverless workgroup"
  value       = local.workgroup_arn
}

output "iam_role_arn" {
  description = "IAM role ARN attached to the Redshift Serverless namespace"
  value       = local.role_arn
}

output "security_group_id" {
  description = "Security Group ID used by the workgroup"
  value       = local.security_group_id
}