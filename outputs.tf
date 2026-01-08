output "vm_external_ip" {
  value = google_compute_instance.bindplane_vm.network_interface[0].access_config[0].nat_ip
}

output "gcs_bucket_name" {
  value = google_storage_bucket.bindplane_bucket.name
}
