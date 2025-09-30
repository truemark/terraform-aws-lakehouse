variable "catalog_id" {
  description = "Glue Data Catalog ID (defaults to current account)."
  type        = string
  default     = null
}

variable "data_lake_admins" {
  description = "IAM principal ARNs to set as Lake Formation admins."
  type        = list(string)
}

variable "create_default_lf_tags" {
  description = "Create starter LF-Tags (environment, pii)."
  type        = bool
  default     = true
}

variable "lf_tags" {
  description = "Additional LF-Tags to create: map(tag_name => { values = [...] })."
  type = map(object({
    values = list(string)
  }))
  default = {}
}