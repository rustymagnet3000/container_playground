variable "elb_port" {
  description = "port used by AWS CLB load balancer"
  type = number
  default = 80
}

variable "server_port" {
  description = "port used by AWS Public web server"
  type = number
  default = 8080
}
