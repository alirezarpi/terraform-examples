output "nomad_url" {
  value = "http://${aws_instance.nomad-node[0].public_ip}:4646/ui/"
}

output "consul_url" {
  value = "http://${aws_instance.nomad-node[0].public_ip}:8500/ui/"
}

output "fabio_url" {
  value = "http://${aws_instance.nomad-node[0].public_ip}:9998/"
}
