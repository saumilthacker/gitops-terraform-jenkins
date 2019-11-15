output "instance_ips" {
  value = ["${aws_eip.default.*.public_ip}"]
}
