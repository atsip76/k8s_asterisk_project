output "k8s_node_external_ip" {
  value = "${google_compute_instance.k8s_node.*.network_interface.0.access_config.0.nat_ip}"
}

output "k8s_node_lb_http_external_ip" {
  value = "${google_compute_address.k8s_node_lb_http_ip.address}"
}