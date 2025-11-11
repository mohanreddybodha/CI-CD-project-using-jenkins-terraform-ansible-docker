terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "web_sg" {
  name        = "flask-ui-sg"
  description = "Allow HTTP(80) and SSH(22)"

  ingress { from_port = 80  to_port = 80  protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 22  to_port = 22  protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }

  egress  { from_port = 0   to_port = 0   protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_instance" "web" {
  ami                    = "ami-0f58b397bc5c1f2e8" # Amazon Linux 2, ap-south-1 (verify before apply)
  instance_type          = "t2.micro"
  key_name               = "YOUR_KEYPAIR_NAME"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = { Name = "flask-ui-docker" }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
