variable "aws_region" {
  description = "AWS region to reflect in table-bucket names (defaults to provider region)."
  type        = string
  default     = null
}

variable "bucket_count" {
  description = "How many S3 Tables table-buckets to create (sequentially numbered)."
  type        = number
  default     = 1
}

variable "start_index" {
  description = "Starting number for the {##} component; 1 => 01."
  type        = number
  default     = 1
}

variable "attach_policy" {
  description = "Attach a table-bucket policy granting S3 Tables API access to `policy_principals`."
  type        = bool
  default     = false
}

variable "policy_principals" {
  description = "List of IAM principal ARNs to grant `s3tables:*` if `attach_policy = true`."
  type        = list(string)
  default     = []
}