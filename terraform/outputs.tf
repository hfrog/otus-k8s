output "internal_ip" {
  value = { for name in local.names : name => yandex_compute_instance.instance[name].network_interface[0].ip_address }
}

output "external_ip" {
  value = { for name in local.names : name => yandex_compute_instance.instance[name].network_interface[0].nat_ip_address }
}
