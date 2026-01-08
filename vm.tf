resource "tls_private_key" "vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.vm_name}-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "bindplane_ui" {
  name    = "${var.vm_name}-ui"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["3001"]
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
}

resource "null_resource" "install_stack" {
  depends_on = [google_compute_instance.bindplane_vm]

  connection {
    type        = "ssh"
    host        = google_compute_instance.bindplane_vm.network_interface[0].access_config[0].nat_ip
    user        = "ubuntu"
    private_key = tls_private_key.vm_key.private_key_pem
  }

  provisioner "file" {
    source      = "setup_bindplane.sh"
    destination = "/home/ubuntu/setup_bindplane.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/setup_bindplane.sh",
      "sudo /home/ubuntu/setup_bindplane.sh '${var.db_user}' '${var.db_pass}' '${var.bp_admin_user}' '${var.bp_admin_pass}' '${var.bindplane_license_key}'"
    ]
  }
}
