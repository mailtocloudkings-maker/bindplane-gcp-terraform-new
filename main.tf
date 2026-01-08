terraform {
  required_providers {
    google = { source = "hashicorp/google", version = ">= 4.0" }
    tls    = { source = "hashicorp/tls", version = ">= 4.0" }
  }

  backend "gcs" {
    bucket = "bindplane-tf-state-bucket"   # Change if needed
    prefix = "bindplane/state"
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# Generate SSH Key
resource "tls_private_key" "vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Firewall for SSH
resource "google_compute_firewall" "ssh" {
  name    = "${var.vm_name}-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bindplane"]
}

# Firewall for BindPlane UI
resource "google_compute_firewall" "bindplane_ui" {
  name    = "${var.vm_name}-ui"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["3001"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bindplane"]
}

# Firewall for HTTP
resource "google_compute_firewall" "http" {
  name    = "${var.vm_name}-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bindplane"]
}

# Firewall for HTTPS
resource "google_compute_firewall" "https" {
  name    = "${var.vm_name}-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bindplane"]
}

# Compute VM
resource "google_compute_instance" "bindplane_vm" {
  name         = var.vm_name
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.vm_key.public_key_openssh}"
  }

  tags = ["bindplane"]

  depends_on = [
    google_compute_firewall.ssh,
    google_compute_firewall.bindplane_ui,
    google_compute_firewall.http,
    google_compute_firewall.https
  ]
}

# GCS Bucket
resource "google_storage_bucket" "bindplane_bucket" {
  name     = var.bucket_name
  location = var.region
}

# Outputs
output "vm_external_ip" {
  value = google_compute_instance.bindplane_vm.network_interface[0].access_config[0].nat_ip
}

output "gcs_bucket_name" {
  value = google_storage_bucket.bindplane_bucket.name
}

output "ssh_private_key" {
  value     = tls_private_key.vm_key.private_key_pem
  sensitive = true
}
