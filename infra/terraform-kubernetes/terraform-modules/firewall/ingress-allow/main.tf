resource "google_compute_firewall" "default" {
  name        = "${var.name}"
  description = "${var.description}"
  network     = "${var.network}"
  priority    = "${var.priority}"

  allow {
    protocol = "tcp"
    ports    = ["5061", "22", "8888"]
  }

  allow {
    protocol = "udp"
    ports    = ["10000-20000", "5060", "5160"]
  }

  source_ranges = "${var.source_ranges}"
  target_tags   = "${var.target_tags}"
  source_tags   = "${var.source_tags}"
}
