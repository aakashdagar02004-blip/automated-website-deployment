terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "public" {
  id = "subnet-05cbbdff4b5dd0533"
}

data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_security_group" "website_sg" {
  name        = "automated-website-sg"
  description = "Allow SSH from my IP and HTTP website traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from my current public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["223.181.16.80/32"]
  }

  ingress {
    description = "HTTP website access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "automated-website-sg"
    Project = "automated-website-deployment"
  }
}

resource "aws_instance" "website" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnet.public.id
  availability_zone           = "ap-south-1a"
  key_name                    = "ansible-key"
  vpc_security_group_ids      = [aws_security_group.website_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name    = "automated-website-server"
    Project = "automated-website-deployment"
  }
}

output "website_public_ip" {
  description = "Public IP address of the website server"
  value       = aws_instance.website.public_ip
}

output "website_public_dns" {
  description = "Public DNS name of the website server"
  value       = aws_instance.website.public_dns
}
