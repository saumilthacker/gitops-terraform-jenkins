output "instance_ips" {
  value = ["${aws_eip.default1.*.public_ip}"]
}
