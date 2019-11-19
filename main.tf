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
}
# Create elastic-ip
resource "aws_eip" "default1" {
  instance = "${aws_instance.default.id}"
  vpc      = true
  }
 #Create vpc 
resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr_vpc}"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

 #Create subnet
resource "aws_subnet" "subnet_public" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.cidr_subnet}"
  map_public_ip_on_launch = "true"
  availability_zone = "${var.availability_zone}"
}
#Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}
# Create route table
resource "aws_route_table" "rtb_public" {
  vpc_id = "${aws_vpc.vpc.id}"
route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.igw.id}"
  }
}

resource "aws_route_table_association" "associate_to_subnet" {
  subnet_id      = "${aws_subnet.subnet_public.id}"
  route_table_id = "${aws_route_table.rtb_public.id}"
}

data "aws_acm_certificate" "fetch_certificate_arn" {
  domain   = "www.moogsoft.me"
  statuses = ["ISSUED"]
  most_recent = true
  }

# Create network load balancer
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "network"
  subnet_mapping {
    subnet_id     = "${aws_subnet.subnet_public.id}"
  }
  depends_on = ["aws_instance.default","aws_vpc.vpc","aws_subnet.subnet_public"]
  }
#CREATING A TARGET GROUP FOR LOAD BALANCER.
resource "aws_lb_target_group" "test" {
  name     = "aws-targetgroup"
  port     = 443
  protocol = "TLS"
  target_type = "instance"
  vpc_id   = "${aws_vpc.vpc.id}"
}
#ATTACHING THE PRIVATE HOSTS TO LOAD BALANCER'S TARGET GROUP.
resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = "${aws_lb_target_group.test.arn}"
  target_id        = "${aws_instance.default.id}"
  port             = 443
}
#Attaching listner
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.test.arn}"
  port              = "443"
  protocol          = "TLS"
  certificate_arn   = "${data.aws_acm_certificate.fetch_certificate_arn.arn}"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.test.arn}"
  }
  
}

# Create EC2 instance
resource "aws_instance" "default" {
  ami                    = "${var.ami}"
  count                  = "${var.count}"
  subnet_id = "${aws_subnet.subnet_public.id}"
  key_name               = "${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  source_dest_check      = "false"
  instance_type          = "${var.instance_type}"
  user_data = "${file("permit_root.sh")}"
root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 100
    },
  ]
  tags {
    Name = "terraform-default"
  }
  depends_on = ["aws_instance.default", "aws_key_pair.generated_key"] 
}

#Setting up Route 53
resource "aws_route53_zone" "example" {
  name = "www.moogsoft.me"
}
resource "aws_route53_record" "route" {
  zone_id = "${aws_route53_zone.example.zone_id}"
  name    = ""
  type    = "CNAME"
  records = ["${aws_lb.test.dns_name}"]
  ttl     = "300"
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
resource "null_resource" "Script_provisioner" {
  triggers {
    public_ip = "${aws_eip.default1.public_ip}"
  }

  connection {
    type = "ssh"
    host = "${aws_eip.default1.public_ip}"
    user = "root"
    port = "22"
    private_key = "${tls_private_key.jenkins.private_key_pem}"
    agent = false
  }
  #depends_on = ["tls_private_key.jenkins"]
  provisioner "local-exec" {
    command = "sleep 250"
  }
provisioner "file" {
    source      = "test.sh"
    destination = "/home/centos/test.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/centos/test.sh",
      "sh /home/centos/test.sh ${var.build_number}"
    ]
  }
depends_on = ["aws_instance.default"]
  }
