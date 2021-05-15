variable project_id {
  description = "Project id of My First Project"
}

variable region {
  description = "Region"
}

variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "europe-north1-a"
}

variable "cred_file" {
  description = "credential json"
  type        = string 
  # Значение по умолчанию
  default = "/home/itokareva/otusk8s-188afcfc4e98.json" 
}

variable node_machine_type {
  description = "Node machine type"
  default     = "n1-standard-2"
} 
