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

resource "local_file" "vm_private_key" {
  filename        = "${path.module}/vm_key.pem"
  content         = tls_private_key.vm_key.private_key_pem
  file_permission = "0600"
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.vm_name}-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "3001"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "bindplane_vm" {
  name         = var.vm_name
  zone         = var.zone
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

  tags = ["ssh"]
}

resource "google_storage_bucket" "bindplane_bucket" {
  name     = var.bucket_name
  location = var.region
}

resource "null_resource" "install_stack" {
  depends_on = [google_compute_instance.bindplane_vm]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.vm_key.private_key_pem
    host        = google_compute_instance.bindplane_vm.network_interface[0].access_config[0].nat_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/setup_bindplane.sh", {
      db_user              = var.db_user
      db_pass              = var.db_pass
      bp_admin_user        = var.bp_admin_user
      bp_admin_pass        = var.bp_admin_pass
      bindplane_license_key = var.bindplane_license_key
    })
    destination = "/home/ubuntu/setup_bindplane.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/setup_bindplane.sh",
      "sudo bash /home/ubuntu/setup_bindplane.sh | tee /var/log/bindplane-install.log"
    ]
  }
}
