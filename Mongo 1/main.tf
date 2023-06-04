terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

    backend "s3" {
    bucket         	   = "tfstatefiles007"
    key              	   = "EC2/Mongo_1/terraform.tfstate"
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
  associate_public_ip_address = false
  tags = {
    Name = "Mongo_1"
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


data "aws_security_group" "bastion_sec" {
  name        = "bastion_sec"
}

