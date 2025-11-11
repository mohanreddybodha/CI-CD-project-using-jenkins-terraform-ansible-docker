terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow inbound traffic for web UI"

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow ssh traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0dee22c13ea7a9a16" # Amazon Linux 2 for ap-south-1
  instance_type          = "t2.micro"
  key_name               = "mohan1"  #  Replace with your actual key pair name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = { 
    Name = "flask-ui-docker"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
