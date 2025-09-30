variable "aws_region" {
  description = "Region to embed in bucket names; null uses provider region."
  type        = string
  default     = null
}

variable "bucket_count" {
  description = "How many buckets to create (applies to both classic S3 and S3 Tables)."
  type        = number
  default     = 1
}

variable "start_index" {
  description = "Starting number for the {##} component in names (1 => 01)."
  type        = number
  default     = 1
}

variable "create_tables_buckets" {
  description = "Create S3 Tables table-buckets."
  type        = bool
  default     = true
}

variable "create_classic_buckets" {
  description = "Create standard S3 buckets."
  type        = bool
  default     = true
}

variable "attach_policy" {
  description = "Attach policies granting access to policy_principals (both classic S3 and S3 Tables)."
  type        = bool
  default     = false
}

variable "policy_principals" {
  description = "List of IAM principal ARNs to grant access if attach_policy = true."
  type        = list(string)
  default     = []
}

variable "force_destroy" {
  description = "Allow terraform destroy of non-empty classic S3 buckets (useful for demos)."
  type        = bool
  default     = false
}