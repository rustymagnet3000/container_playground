provider "aws" {
  region = "eu-west-2"
}

resource "aws_instance" "example" {
    ami           = "ami-0fbec3e0504ee1970"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello RM World" > index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF
    tags = {
        Name = "terraform-example"
    }
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
  ingress {
    description = "Open port 8080 ingress traffic"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "server_port" {
  description = "port used by AWS Public web server"
  type = number
  default = 8080
}

output "public_ip" {
  value = aws_instance.example.public_ip
  description = "Server's Public IP"
  sensitive = false
}