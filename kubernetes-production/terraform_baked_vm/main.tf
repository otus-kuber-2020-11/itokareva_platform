terraform {
  required_version = ">= 0.12.8"
}

provider "google" {

  project = var.project_id
  region  = var.region
  zone    = var.zone
  credentials = file(var.cred_file)

}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file(var.cred_file)
}

resource "google_compute_instance" "k8s-onega" {
  name         = "k8s-node-${count.index}"
  tags         = ["k8s"]
  count        = 4
  machine_type = var.node_machine_type

  boot_disk {
    initialize_params {
#      image = "ubuntu-1804-lts" - это стандартный образ из коробки (GCE)
      image = "k8s-nodes-1620505266"  # образ с предустановленными tools
    }
  }


  network_interface {
    network = "default"
    access_config {}
  }

}
