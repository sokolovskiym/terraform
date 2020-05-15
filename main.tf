provider "google" {
  version = "3.5.0"

  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone

}

resource "google_compute_project_metadata_item" "default" {
  project = "${var.project}"
  key = "ssh-keys"
  value = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
}

resource "google_compute_address" "vm_static_ip" {
  name = "terraform-static-ip"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = "terraform-network"

  allow {
    protocol = "tcp"
    ports = ["22"]
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
#  machine_type = "n1-standard-2"
  tags         = ["web", "dev"]
  provisioner "local-exec" {
    command = "echo ${google_compute_instance.vm_instance.name}:  ${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip} >> ip_address.txt"
  
#  metadata = {
#    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
#   }
  }
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }
}
