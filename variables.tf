variable "count" {
  default = 1
}

variable "key_name" {
  description = "Private key name to use with instance"
  default     = "soumil-moog"
}

variable "instance_type" {
  description = "AWS instance type"
  default     = "t2.xlarge"
}

variable "ami" {
  description = "Base AMI to launch the instances"

  # Centos ami
  default = "ami-02eac2c0129f6376b"
}
variable "build_number" {
  description = "Build Number"
}
variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default = "10.0.0.0/16"
}
variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default = "10.0.1.0/24"
}
variable "availability_zone" {
  description = "availability zone to create subnet"
  default = "us-east-1a"
}

