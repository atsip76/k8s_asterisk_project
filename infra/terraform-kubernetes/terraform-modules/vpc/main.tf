resource "google_compute_network" "default" {
  name                    = "${var.name}"
  description             = "${var.description}"
  auto_create_subnetworks = "true"
}
