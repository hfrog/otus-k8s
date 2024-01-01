terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    region = "ru-central1"
    key    = "terraform/main.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  zone = "ru-central1-b"
}

variable "image_id" {
  default = "fd85an6q1o26nf37i2nl" # ubuntu-20-04-lts-v20231218
}

variable "ssh-keys" {
#  default = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
}

resource "yandex_compute_instance" "vm-1" {
  name = "terraform1"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 8
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = var.ssh-keys
  }
}

resource "yandex_compute_instance" "vm-2" {
  name = "terraform2"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 8
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = var.ssh-keys
  }
}

resource "yandex_compute_instance" "vm-3" {
  name = "terraform3"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 8
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = var.ssh-keys
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}
