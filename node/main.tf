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
    key                = "EC2/node/terraform.tfstate"
    region         	   = "us-west-2"
  }
}


provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  profile                  = "default"
}


resource "aws_instance" "ec2_instance" {
  count         = 3
  ami           = "ami-04e914639d0cca79a"
  subnet_id     = "subnet-00a98551581edec3e"
  instance_type = "t2.micro"
  key_name      = "generic-ssh"
  security_groups = [data.aws_security_group.bastion_sec.id]
  associate_public_ip_address = false
  tags = {
    Name = "node_${count.index + 1}"
  }
}

resource "aws_ebs_volume" "ebs_volumes" {
  count              = 3
  availability_zone  = "us-west-2a"
  size               = 20
  type               = "gp2"
}

resource "aws_volume_attachment" "volume-attachment" {
  count                          = length(aws_instance.ec2_instance)
  device_name                    = "/dev/xvdb"
  volume_id                      = aws_ebs_volume.ebs_volumes[count.index].id
  instance_id                    = aws_instance.ec2_instance[count.index].id
  stop_instance_before_detaching = true
}


data "aws_security_group" "bastion_sec" {
  name        = "bastion_host_sec"
}

