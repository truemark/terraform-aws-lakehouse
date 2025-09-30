variable "domain_name" {
  description = "SageMaker Studio domain name (must be unique per account/region)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Studio will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Studio domain."
  type        = list(string)
}

variable "kms_key_id" {
  description = "Optional KMS key for encryption at rest (Studio Domain)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}

# Unified/shared execution role for all users unless overridden per user profile
variable "create_execution_role" {
  description = "Create a shared Studio execution role."
  type        = bool
  default     = true
}

variable "execution_role_name" {
  description = "Name for the shared Studio execution role (if created)."
  type        = string
  default     = "SageMakerStudioUnifiedExecutionRole"
}

variable "attach_data_access_policy" {
  description = "Attach inline policy with S3/S3 Tables data access to the shared execution role."
  type        = bool
  default     = true
}

variable "raw_s3_bucket_arns" {
  description = "List of classic S3 bucket ARNs (raw/landing) to allow read/write."
  type        = list(string)
  default     = []
}

variable "s3tables_table_bucket_arns" {
  description = "List of S3 Tables table-bucket ARNs to allow s3tables:* (governed by LF separately)."
  type        = list(string)
  default     = []
}

# Team users
variable "user_profiles" {
  description = <<EOT
List of user profiles. Each object:
{
  name                = "leonard",
  execution_role_arn  = optional("arn:aws:iam::...:role/CustomExecRole") # overrides shared role
  tags                = optional({ "Team" = "DS" })
}
EOT
  type = list(object({
    name               = string
    execution_role_arn = optional(string)
    tags               = optional(map(string))
  }))
  default = []
}
