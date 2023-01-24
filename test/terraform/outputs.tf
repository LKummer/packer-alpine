output "ssh_ip" {
  value = module.machine.ssh_ip
}

output "ssh_port" {
  value = 2222
}

output "user" {
  value = module.machine.user
}

output "password" {
  value     = module.machine.password
  sensitive = true
}
