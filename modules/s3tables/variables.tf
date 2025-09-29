# ---- region used in names (falls back to provider region if null) ----
variable "aws_region" {
  description = "AWS region to reflect in bucket names (defaults to provider region)."
  type        = string
  default     = null
}

# ---- how many numbered buckets to create; start index controls the 01, 02, ... suffix ----
variable "bucket_count" {
  description = "How many buckets to create (applies to both classic S3 and S3 Tables unless creation is disabled)."
  type        = number
  default     = 1
}

variable "start_index" {
  description = "Starting number for the {##} component in names; 1 => 01."
  type        = number
  default     = 1
}

# ---- which bucket types to create ----
variable "create_tables_buckets" {
  description = "Create S3 Tables table-buckets named {account}-lakehouse-table-bucket-##-{region}."
  type        = bool
  default     = true
}

variable "create_classic_buckets" {
  description = "Create standard S3 buckets named {account}-lakehouse-bucket-##-{region}."
  type        = bool
  default     = true
}

# ---- policies applied to BOTH kinds when enabled ----
variable "attach_policy" {
  description = "Attach a bucket policy granting access to `policy_principals` (applies to both classic S3 and S3 Tables)."
  type        = bool
  default     = false
}

variable "policy_principals" {
  description = "List of IAM principal ARNs to grant access if `attach_policy = true`."
  type        = list(string)
  default     = []
}

# ---- classic S3 only: allow destroy of non-empty buckets (useful for demos) ----
variable "force_destroy" {
  description = "If true, allow terraform destroy of non-empty classic S3 buckets."
  type        = bool
  default     = false
}