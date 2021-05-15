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

resource "google_compute_instance" "k8s-ladoga" {
  name         = "k8s-master"
  tags         = ["k8s-master"]
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

  connection {
    type  = "ssh"
    host  = google_compute_instance.k8s-ladoga.network_interface.0.access_config[0].nat_ip
    agent = false
    user  = "itokareva"
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    script = "install_k8s.sh"
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no ${google_compute_instance.k8s-ladoga.network_interface.0.access_config[0].nat_ip}:/home/itokareva/join_node.sh ."
  }


}

resource "google_compute_instance" "k8s-onega" {
  name         = "k8s-worker-${count.index}"
  tags         = ["k8s-worker"]
  count        = 3
  machine_type = var.node_machine_type
  depends_on = [google_compute_instance.k8s-ladoga]

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

 connection {
   type  = "ssh"
   host  = self.network_interface.0.access_config[0].nat_ip
   agent = false
   user  = "itokareva"
   private_key = file(var.private_key_path)
 }

  provisioner "remote-exec" {
    script = "join_node.sh"
  }
 # provisioner "local-exec" {
 #   command = "sed -i '1s;^;sudo ;' join_node.sh; cat join_node.sh | ssh -o StrictHostKeyChecking=no ${self.network_interface.0.access_config[0].nat_ip}"
 # }

}
