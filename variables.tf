variable "project_id" {}
variable "region" {}
variable "zone" {}
variable "vm_name" {}
variable "bucket_name" {}
variable "credentials_file" {}

variable "db_user" {}
variable "db_pass" {}
variable "bp_admin_user" {}
variable "bp_admin_pass" {}

variable "bindplane_license_key" {
  sensitive = true
}
