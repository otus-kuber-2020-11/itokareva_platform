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

variable "logging_service" {
  description = "The logging service that the cluster should write logs to. Available options include logging.googleapis.com/kubernetes, logging.googleapis.com (legacy), and none"
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "The monitoring service that the cluster should write metrics to. Automatically send metrics from pods in the cluster to the Stackdriver Monitoring API. VM metrics will be collected by Google Compute Engine regardless of this setting. Available options include monitoring.googleapis.com/kubernetes, monitoring.googleapis.com (legacy), and none"
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "cred_file" {
  description = "credential json"
  type        = string 
  # Значение по умолчанию
  default = "~/otusk8s-188afcfc4e98.json"
}
 
variable "cluster_name" {
  description = "cluster_name"
  type        = string
}
