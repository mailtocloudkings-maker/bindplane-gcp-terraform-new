provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

resource "tls_private_key" "vm_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_compute_firewall" "allow_all" {
  name    = "${var.vm_name}-fw"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "3001"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "bindplane_vm" {
  name         = var.vm_name
  machine_type = "e2-medium"
  zone         = var.zone

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
}

resource "google_storage_bucket" "bindplane_bucket" {
  name     = var.bucket_name
  location = var.region
}

resource "null_resource" "install_bindplane" {
  depends_on = [google_compute_instance.bindplane_vm]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.vm_key.private_key_pem
    host        = google_compute_instance.bindplane_vm.network_interface[0].access_config[0].nat_ip
  }

  provisioner "file" {
    source      = "${path.module}/setup_bindplane.sh"
    destination = "/home/ubuntu/setup_bindplane.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/setup_bindplane.sh",
      "sudo DB_USER='${var.db_user}' DB_PASS='${var.db_pass}' BP_ADMIN_USER='${var.bp_admin_user}' BP_ADMIN_PASS='${var.bp_admin_pass}' BINDPLANE_LICENSE_KEY='${var.bindplane_license_key}' bash /home/ubuntu/setup_bindplane.sh | tee /var/log/bindplane-install.log"
    ]
  }
}
