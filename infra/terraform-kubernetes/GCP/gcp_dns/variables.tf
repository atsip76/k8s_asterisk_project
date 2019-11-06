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
