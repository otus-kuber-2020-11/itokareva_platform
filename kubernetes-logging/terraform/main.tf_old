provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

resource "google_container_cluster" "webserf" {
  name     = "webserf"
  location = "europe-north1-a"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  monitoring_service       = var.monitoring_service 
  logging_service          = var.logging_service


  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "webserf-pool"
  location   = "europe-north1-a"
  cluster    = google_container_cluster.webserf.name
  node_count = 3

  node_config {
    preemptible  = true
    machine_type = "e2-standard-2"

    metadata = {
      disable-legacy-endpoints = "true"
    }

#    oauth_scopes = [
#      "https://www.googleapis.com/auth/logging.write",
#      "https://www.googleapis.com/auth/monitoring",
#    ]

  }
}
