output "public_ip" {
  value = aws_instance.example.public_ip
  description = "Server's Public IP"
  sensitive = false
}

data "aws_availability_zones" "all" {}


# Output DNS name for simpler testing
output "clb_dns_name" {
  value = aws_elb.example.dns_name
  description = "Domain name of Load Balancer"
}