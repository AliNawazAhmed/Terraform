terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    
  }

  required_version = ">= 1.2.0"

    backend "s3" {
    bucket         	   = "bastion-1"
    key              	 = "EC2/bastion-host/terraform.tfstate"
    region         	   = "us-west-2"
  }
}


provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  profile                  = "default"
}


resource "aws_instance" "ec2_instance" {
  ami           = "ami-04e914639d0cca79a"
  subnet_id     = "subnet-00a98551581edec3e"
  instance_type = "t2.micro"
  key_name      = "generic-ssh"
  security_groups = [aws_security_group.bastion_sec.id]
  tags = {
    Name = "bastion-host"
  }
}

resource "aws_ebs_volume" "ebs_volumes" {
   availability_zone = "us-west-2a"
  size = 20
  type = "gp2"
}

resource "aws_volume_attachment" "volume_attachments" {
 
  device_name                    = "/dev/sdh"
  instance_id                    = aws_instance.ec2_instance.id
  volume_id                      = aws_ebs_volume.ebs_volumes.id
  stop_instance_before_detaching = true
}


resource "aws_security_group" "bastion_sec" {
  name        = "bastion_host_sec"
  description = "Allow SSH"


  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}


output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.ec2_instance.public_ip
}