output "private_ip" {
  description = "Private IP of the instance for Bastion port-forwarding sessions."
  value       = module.free_arm_instance.private_ip[0]
}

output "private_ips" {
  description = "Private IPs of all instances for Bastion sessions."
  value       = module.free_arm_instance.private_ip
}
