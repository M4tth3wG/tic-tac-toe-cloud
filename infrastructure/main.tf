terraform {
  required_providers {
    aws = { # Specify required AWS provider version
      source  = "hashicorp/aws"
      version = ">= 5.1"
    }
  }
  required_version = ">= 1.2.0" # Specify required Terraform version
}

provider "aws" {
  region = "us-east-1" # Set AWS provider configuration for the us-east-1 region.
}

module "tic_tac_toe_vpc" { # Create VPC module
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

resource "aws_security_group" "allow_ssh_http" { # Create security group for SSH and HTTP
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic and all outbound traffic"
  vpc_id      = module.tic_tac_toe_vpc.vpc_id
  tags = {
    Name = "allow-ssh-http"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" { # Add egress rule for all outbound IPv4 traffic
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all ports
}
resource "aws_vpc_security_group_ingress_rule" "allow_http_backend" { # Add ingress rule for TCP traffic on port 8080
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_frontend" { # Add ingress rule for TCP traffic on port 3000
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 3000
  to_port           = 3000
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" { # Add ingress rule for SSH traffic on port 22
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_key_pair" "app_key_pair" { # Create AWS key pair for SSH connection
  key_name   = "app_key_pair"
  public_key = file("keys/id_rsa.pub")
}

resource "aws_instance" "app_server" { # Create AWS instance
  ami                         = "ami-051f8a213df8bc089"
  instance_type               = "t2.micro"
  subnet_id                   = module.tic_tac_toe_vpc.public_subnets[0]
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.allow_ssh_http.id]
  key_name                    = aws_key_pair.app_key_pair.key_name

  connection { # SSH connection configuration
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("keys/id_rsa")
    host        = self.public_ip
  }

  provisioner "remote-exec" { # Remote execution provisioner to install Docker and Docker Compose
    inline = [
      "sudo yum update -y",
      "sudo yum install docker -y",
      "sudo service docker start",
      "sudo usermod -aG docker ec2-user", # This ensures the ec2-user has permissions to run Docker commands
      "sudo curl -L https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
    ]
  }

  provisioner "file" { # Provisioner to transfer compose.yaml file
    source      = "../compose.yaml"
    destination = "/home/ec2-user/compose.yaml"
  }

  provisioner "file" { # Provisioner to transfer docker-compose.service file
    source      = "../docker-compose.service"
    destination = "/tmp/docker-compose.service"
  }

  provisioner "remote-exec" { # Remote execution provisioner to set up Docker Compose service
    inline = [
      "sudo mv /tmp/docker-compose.service /etc/systemd/system/docker-compose.service", # Move with elevated permissions
      "sudo chown root:root /etc/systemd/system/docker-compose.service",                # Ensure correct ownership
      "sudo systemctl daemon-reload",
      "sudo systemctl enable docker-compose.service",
      "sudo systemctl start docker-compose.service"
    ]
  }
}