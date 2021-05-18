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

data "google_compute_instance" "k8s-ladoga" {
  name = "k8s-master"
}

data "google_compute_instance" "k8s-onega" {
 name = "k8s-worker-2"

}
resource "null_resource" "k8s-master-upgrade" {

  connection {
    type  = "ssh"
    host  = data.google_compute_instance.k8s-ladoga.network_interface.0.access_config[0].nat_ip
    agent = false
    user  = "itokareva"
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    script = "upgrade_master.sh"
  }

  provisioner "remote-exec" {
    inline = [
         "kubectl drain ${data.google_compute_instance.k8s-onega.name} --ignore-daemonsets",
         "kubectl get nodes -o wide"
        ]
  }


}

resource "null_resource" "k8s-worker-0-upgrade" {

 depends_on = [null_resource.k8s-master-upgrade]

 connection {
   type  = "ssh"
   host  = data.google_compute_instance.k8s-onega.network_interface.0.access_config[0].nat_ip 
   agent = false
   user  = "itokareva"
   private_key = file(var.private_key_path)
 }

  provisioner "remote-exec" {
    inline = [
         "sudo apt-get install -y kubelet=1.18.0-00 kubeadm=1.18.0-00",
         "sudo systemctl restart kubelet",
         "kubeadm version; kubelet --version"
          ]
  }

}

resource "null_resource" "k8s-master-uncordon" {

  depends_on = [null_resource.k8s-worker-0-upgrade]
  connection {
    type  = "ssh"
    host  = data.google_compute_instance.k8s-ladoga.network_interface.0.access_config[0].nat_ip
    agent = false
    user  = "itokareva"
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
         "kubectl uncordon ${data.google_compute_instance.k8s-onega.name} --ignore-daemonsets",
         "kubectl get nodes -o wide"
        ]
  }

}



