variable "image_id" {
}

variable "ssh-keys" {
#  default = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
}

variable "master_count" {
}

variable "worker_count" {
}

variable "lb_count" {
}

variable "lb_ip_pool" {
}
