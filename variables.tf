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
  default = "ami-0015b9ef68c77328d"
}
variable "build_number" {
  description = "Build Number"
}
