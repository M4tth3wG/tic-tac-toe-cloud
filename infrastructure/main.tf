terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.1"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

module "tic_tac_toe_vpc" {
  source         = "terraform-aws-modules/vpc/aws"
  name           = "tic-tac-toe-vpc"
  cidr           = "10.0.0.0/16"
  azs            = ["us-east-1b"]
  public_subnets = ["10.0.101.0/24"]
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic and all outbound traffic"
  vpc_id      = module.tic_tac_toe_vpc.vpc_id
  tags = {
    Name = "allow-ssh-http"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all ports
}
resource "aws_vpc_security_group_ingress_rule" "allow_http_backend" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_frontend" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 3000
  to_port           = 3000
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_key_pair" "app_key_pair" {
  key_name   = "app_key_pair"
  public_key = file("keys/id_rsa.pub")
}

resource "aws_instance" "app_server" {
  ami                         = "ami-051f8a213df8bc089"
  instance_type               = "t2.micro"
  subnet_id                   = module.tic_tac_toe_vpc.public_subnets[0]
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  key_name                    = aws_key_pair.app_key_pair.key_name

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("keys/id_rsa")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install docker -y",
      "sudo service docker start",
      "sudo usermod -aG docker ec2-user", # This ensures the ec2-user has permissions to run Docker commands
      "sudo curl -L https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
    ]
  }

  provisioner "file" {
    source      = "../compose.yaml"
    destination = "/home/ec2-user/compose.yaml"
  }

  provisioner "file" {
    source      = "../docker-compose.service"
    destination = "/tmp/docker-compose.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/docker-compose.service /etc/systemd/system/docker-compose.service", # Move with elevated permissions
      "sudo chown root:root /etc/systemd/system/docker-compose.service",                # Ensure correct ownership
      "sudo systemctl daemon-reload",
      "sudo systemctl enable docker-compose.service",
      "sudo systemctl start docker-compose.service"
    ]
  }
}