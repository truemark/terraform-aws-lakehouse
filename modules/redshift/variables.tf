variable "vpc_id" {
  type        = string
  description = "VPC ID where Redshift Serverless will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private/isolated subnet IDs for the workgroup"
}

variable "namespace_name" {
  type        = string
  default     = "redshift-serverless-namespace"
  description = "Name of the Redshift Serverless namespace"
}

variable "workgroup_name" {
  type        = string
  default     = "redshift-serverless-workgroup"
  description = "Name of the Redshift Serverless workgroup"
}

variable "admin_user" {
  type        = string
  default     = "admin"
  description = "Admin username for the Redshift Serverless namespace"
}

variable "admin_password" {
  type        = string
  default     = null
  sensitive   = true
  description = "If null, a random 16-character password is generated"
}

variable "existing_admin_secret_arn" {
  type        = string
  default     = null
  description = "If provided, module will not create a new Secrets Manager secret"
}

variable "database_name" {
  type        = string
  default     = "dev"
  description = "Initial database name created in the namespace"
}

variable "base_capacity" {
  type        = number
  default     = 32
  description = "Redshift Serverless capacity in RPUs (e.g., 8, 16, 32, 64, 128)"
}

variable "publicly_accessible" {
  type        = bool
  default     = false
  description = "Whether the Redshift Serverless endpoint is publicly accessible"
}

variable "enhanced_vpc_routing" {
  type        = bool
  default     = true
  description = "Enable enhanced VPC routing for the workgroup"
}

variable "ingress_cidrs" {
  type        = list(string)
  default     = ["10.8.0.0/16"]
  description = "Allowed CIDR ranges for Redshift port if the module creates the security group"
}

variable "port" {
  type        = number
  default     = 5439
  description = "Redshift connection port"
}

variable "existing_security_group_id" {
  type        = string
  default     = null
  description = "If set, use this security group instead of creating one"
}

variable "iam_role_name" {
  type        = string
  default     = "RedshiftServerlessRole"
  description = "Name for the IAM role Redshift will assume"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources created by this module"
}