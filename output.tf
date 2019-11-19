output "instance_ips" {
  value = ["${aws_eip.default1.*.public_ip}"]
}
output "public_dns" {
  value = "${aws_instance.default.public_dns}"
}
