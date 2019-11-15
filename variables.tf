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
