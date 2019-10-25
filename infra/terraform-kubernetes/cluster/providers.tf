provider "google" {
  version = "2.5.0"
  project = "${var.project_id}"
  region  = "${var.region}"
  credentials = "${file("~/.config/GCP/k8s-asterisk-bef1e09569a7.json")}"
}
