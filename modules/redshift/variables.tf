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
}

variable "workgroup_name" {
  type        = string
  default     = "redshift-serverless-workgroup"
}

variable "admin_user" {
  type        = string
  default     = "admin"
}

variable "admin_password" {
  type        = string
  default     = null
  sensitive   = true
  description = "If null, a random 16-char password is generated"
}

variable "existing_admin_secret_arn" {
  type        = string
  default     = null
  description = "If provided, module will not create a secret"
}

variable "database_name" {
  type        = string
  default     = "dev"
}

variable "base_capacity" {
  type        = number
  default     = 32
  description = "Redshift Serverless RPU (8,16,32,64,128, etc.)"
}

variable "publicly_accessible" {
  type        = bool
  default     = false
}

variable "enhanced_vpc_routing" {
  type        = bool
  default     = true
}

variable "ingress_cidrs" {
  type        = list(string)
  default     = ["10.8.0.0/16"]
  description = "Allowed CIDRs for Redshift port if module creates the SG"
}

variable "port" {
  type        = number
  default     = 5439
}

variable "existing_security_group_id" {
  type        = string
  default     = null
  description = "If set, module uses this SG instead of creating one"
}

variable "iam_role_name" {
  type        = string
  default     = "RedshiftServerlessRole"
}

variable "tags" {
  type        = map(string)
  default     = {}
}