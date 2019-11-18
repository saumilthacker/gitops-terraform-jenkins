# Terraform state will be stored in S3
terraform {
  backend "s3" {
    bucket = "soumil-test-jenkins"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

# Use AWS Terraform provider
provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "jenkins" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "Jenkins-default"
  public_key = "${tls_private_key.jenkins.public_key_openssh}"
    depends_on = ["tls_private_key.jenkins"]
}
# Create elastic-ip
resource "aws_eip" "default1" {
  instance = "${aws_instance.default.id}"
  vpc      = true
  }
# Create vpc 
resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr_vpc}"
  enable_dns_support   = true
  enable_dns_hostnames = true
}
# Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}
# Create subnet
resource "aws_subnet" "subnet_public" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.cidr_subnet}"
  map_public_ip_on_launch = "true"
  availability_zone = "${var.availability_zone}"
}
# Create route table
resource "aws_route_table" "rtb_public" {
  vpc_id = "${aws_vpc.vpc.id}"
route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.igw.id}"
  }
}
# Create network load balancer
#resource "aws_lb" "test" {
#  name               = "test-lb-tf"
#  internal           = false
#  load_balancer_type = "network"
#  subnet_mapping {
#    subnet_id     = "${aws_subnet.subnet_public.id}"
#  }
#  depends_on = ["aws_instance.default","aws_vpc.vpc","aws_subnet.subnet_public"]
#  }

# Create EC2 instance
resource "aws_instance" "default" {
  ami                    = "${var.ami}"
  count                  = "${var.count}"
  subnet_id = "${aws_subnet.subnet_public.id}"
  key_name               = "${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  source_dest_check      = "false"
  instance_type          = "${var.instance_type}"
  user_data = "${file("test.sh")}"
root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 100
    },
  ]
  tags {
    Name = "terraform-default"
  }
  depends_on = ["aws_instance.default", "aws_key_pair.generated_key","aws_vpc.vpc"] 
}

# Create Security Group for EC2
resource "aws_security_group" "default" {
  name = "terraform-default-sg"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  }
