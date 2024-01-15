variable "image_id" {
  default = "fd85an6q1o26nf37i2nl" # ubuntu-20-04-lts-v20231218
#  default = "fd866d9q7rcg6h4udadk" # ubuntu-22-04-lts-v20231225
}

variable "ssh-keys" {
#  default = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
}

variable "master_count" {
  default = 1
}

variable "worker_count" {
  default = 2
}

variable "lb_count" {
  default = 1
}

variable "lb_ip_pool" {
}
