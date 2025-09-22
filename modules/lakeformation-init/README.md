# lakeformation-init

Initializes AWS Lake Formation for your account/environment.

- Sets **data lake admins** (list of IAM principal ARNs)
- (Optional) Creates a small starter set of **LF tags** (`environment`, `pii`)
- Accepts additional LF tags via `lf_tags`

> **S3 Tables note:** With Amazon **S3 Tables**, do **not** register S3 data locations in LF. Instead, enable the **S3 Tables ↔ Lake Formation integration** once per Region (LF console → Data lake locations → *Enable Amazon S3 Tables integration*). After that, govern access on S3 Tables catalog objects (table buckets/namespaces/tables).

## Inputs
- `catalog_id` (string, default = current account)
- `data_lake_admins` (list(string), **required**)
- `create_default_lf_tags` (bool, default `true`)
- `lf_tags` (map(tag_name => { values = [...] }), default `{}`)

## Outputs
- `catalog_id`
- `lf_tags_created`

## Example
```hcl
module "lakeformation" {
  source           = "github.com/your-org/terraform-aws-lakehouse//modules/lakeformation-init"
  data_lake_admins = [
    "arn:aws:iam::123456789012:role/DataLakeAdministrator"
  ]
  lf_tags = {
    domain = { values = ["bi", "ops", "finance"] }
  }
}