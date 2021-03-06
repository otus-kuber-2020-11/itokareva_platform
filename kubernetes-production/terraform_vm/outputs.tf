### The Ansible inventory file
output "inventory" {
value = <<INVENTORY
{ "_meta": {
        "hostvars": {
    %{ for index, name in google_compute_instance.k8s-onega[*].name ~}
           "${name}": {
             "host_name": "${google_compute_instance.k8s-onega[index].name}",
             "host_ext_ip": "${google_compute_instance.k8s-onega[index].network_interface.0.access_config[0].nat_ip}" 
           },  
    %{ endfor ~}
           "dummy": { } 
        }
    
    },
  "docker-host": { 
    "hosts": [
       "${join("\",\"", google_compute_instance.k8s-onega.*.name)}"
              ]
  }

}
    INVENTORY
}
