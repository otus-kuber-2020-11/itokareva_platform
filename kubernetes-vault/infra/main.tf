provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file(var.cred_file)
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file(var.cred_file)
}


resource "google_container_cluster" "ladoga" {
  name     = var.cluster_name 
  location = var.zone
  min_master_version          = "1.18.16-gke.302"
  node_version                = "1.18.16-gke.302"
  enable_legacy_abac          = true

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 3 
  monitoring_service       = var.monitoring_service 
  logging_service          = var.logging_service

   master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
  #provisioner "local-exec" {
  #  command = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.zone} --project ${var.project_id}"
  #}
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "ladoga-pool"
  location   = var.zone 
  cluster    = google_container_cluster.ladoga.name
  node_count = 4
  version    = "1.18.16-gke.302"

  node_config {
    preemptible  = true
    machine_type = "n1-standard-2"
    disk_size_gb = 30

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
