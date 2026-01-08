resource "google_storage_bucket" "bindplane_bucket" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true
}
