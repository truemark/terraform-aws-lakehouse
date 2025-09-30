output "domain_id" {
  value       = aws_sagemaker_domain.this.id
  description = "SageMaker Studio domain ID."
}

output "domain_arn" {
  value       = aws_sagemaker_domain.this.arn
  description = "SageMaker Studio domain ARN."
}

output "execution_role_arn" {
  value       = var.create_execution_role ? aws_iam_role.studio_exec[0].arn : null
  description = "Shared execution role ARN (if created)."
}

output "user_profiles" {
  value = {
    for k, up in aws_sagemaker_user_profile.team :
    k => {
      id  = up.id
      arn = up.arn
    }
  }
  description = "Map of user profile name -> {id, arn}."
}
