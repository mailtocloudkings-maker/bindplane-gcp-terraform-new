# GCP and VM settings
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "vm_name" {
  description = "Name of the VM to create"
  type        = string
}

variable "bucket_name" {
  description = "GCS Bucket name"
  type        = string
}

# Database settings
variable "db_user" {
  description = "PostgreSQL username"
  type        = string
}

variable "db_pass" {
  description = "PostgreSQL password"
  type        = string
}

# BindPlane Admin
variable "bp_admin_user" {
  description = "BindPlane admin username"
  type        = string
}

variable "bp_admin_pass" {
  description = "BindPlane admin password"
  type        = string
}

variable "bindplane_license_key" {
  description = "BindPlane license key"
  type        = string
  sensitive   = true
}

# Credentials
variable "credentials_file" {
  description = "Path to GCP service account JSON key"
  type        = string
}

