locals {
  lb_names = toset([for i in range(1, var.lb_count + 1) : "lb-${i}"])
  names = toset(concat(
    [for i in range(1, var.master_count + 1) : "master-${i}"],
    [for i in range(1, var.worker_count + 1) : "worker-${i}"],
    tolist(local.lb_names)
  ))
}

# reserve static external IP for load balancers
resource "yandex_vpc_address" "lb" {
  for_each = local.lb_names
  name     = each.value

  external_ipv4_address {
    zone_id = "ru-central1-b"
  }
}

resource "yandex_compute_instance" "instance" {
  for_each = local.names
  name     = each.value
  hostname = each.value

  allow_stopping_for_update = true

  resources {
    cores         = 2
    core_fraction = 20
    memory        = startswith(each.value, "lb") ? 2 : each.value == "master-1" ? 3 : 8
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = startswith(each.value, "lb") ? 5 : 25
    }
  }

  network_interface {
    subnet_id      = yandex_vpc_subnet.subnet-1.id
    nat            = true
    nat_ip_address = startswith(each.value, "lb") ? yandex_vpc_address.lb[each.value].external_ipv4_address[0].address : null
    ip_address     = each.value == "master-1" ? "192.168.10.19" : null
  }

  metadata = {
    ssh-keys = var.ssh-keys
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_route_table" "table1" {
  network_id     = yandex_vpc_network.network-1.id
  static_route {
    destination_prefix = var.lb_ip_pool
    next_hop_address   = "192.168.10.19"
  }
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
  route_table_id = yandex_vpc_route_table.table1.id
}

resource "yandex_vpc_default_security_group" "group1" {
  network_id = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "ANY"
    description    = "Any internal"
    v4_cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
