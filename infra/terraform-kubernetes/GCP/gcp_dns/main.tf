terraform {
  required_version = ">= 0.12.7"
}

provider "google" {
  version = "~> 2.11.0"
  project = var.project
  region  = var.region
  credentials = "${file("~/.config/GCP/test-otus-833c715049ee.json")}"
}

data "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx"
    namespace = "nginx-ingress"
  }
}

resource "google_dns_record_set" "a_gitlab" {
  name = "gitlab.${google_dns_managed_zone.prod.dns_name}"
  managed_zone = "${google_dns_managed_zone.prod.name}"
  type = "A"
  ttl  = 300

  rrdatas = ["8.8.8.8"]
}


resource "google_dns_record_set" "a_prometheus" {
  name = "prometheus.${google_dns_managed_zone.prod.dns_name}"
  managed_zone = "${google_dns_managed_zone.prod.name}"
  type = "A"
  ttl  = 300

  rrdatas = ["8.8.8.8"]
}

resource "google_dns_record_set" "a_grafana" {
  name = "grafana.${google_dns_managed_zone.prod.dns_name}"
  managed_zone = "${google_dns_managed_zone.prod.name}"
  type = "A"
  ttl  = 300

  rrdatas = ["8.8.8.8"]
}

