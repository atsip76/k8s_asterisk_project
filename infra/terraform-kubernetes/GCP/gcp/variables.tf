variable "project" {
  description = "The project ID where all resources will be launched."
  type        = string
  default = "project"
}

variable "location" {
  description = "The location (region or zone) of the GKE cluster."
  type        = string
  default = "europe-west1"
}

variable "region" {
  description = "The region for the network. If the cluster is regional, this must be the same region. Otherwise, it should be the region of the zone."
  type        = string
  default = "europe-west1"
}

variable "pool_name" {
  description = "Name node pool"
  type        = string
  default = "test"
}

variable "initial_node_count" {
  description = "Number of nodes"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "Machine type"
  type        = string
  default = "n1-standard-1"
}
# ---------------------------------------------------------------------------------------------------------------------
# Дополнительные параметры
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the Kubernetes cluster."
  type        = string
  default     = "cluster-test"
}

variable "legacy" {
  description = "Enable basic authentication"
  type        = bool
  default     = true
}

variable instance_name {
  description = "Название инстанса"
  default     = "instance"
}

variable instance_tag {
  description = "Тег инстанса по умолчанию"
  default     = "instance_tag"
}

variable instance_network_interface {
  description = "Cеть, к которой присоединить данный интерфейс"
  default     = "default"
}

variable zone {
  description = "Zone"
  default = "europe-west1-b"
}

/* variable public_key_path {
  description = "Путь к public key для ssh"
}
variable private_key_path {
  description = "Путь к private key для ssh"
} */

variable "kubectl_config_path" {
  description = "Path to the kubectl config file. Defaults to $HOME/.kube/config"
  type        = string
  default     = ""
}

variable "horizontal_pod_autoscaling" {
  description = "Whether to enable the horizontal pod autoscaling addon"
  type        = bool
  default     = true
}

variable "http_load_balancing" {
  description = "Whether to enable the http (L7) load balancing addon"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Control whether nodes have internal IP addresses only. If enabled, all nodes are given only RFC 1918 private addresses and communicate with the master via private networking."
  type        = bool
  default     = false
}

variable "disable_public_endpoint" {
  description = "Control whether the master's internal IP address is used as the cluster endpoint. If set to 'true', the master can only be accessed from internal IP addresses."
  type        = bool
  default     = false
}