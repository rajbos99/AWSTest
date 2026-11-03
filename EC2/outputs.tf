output "ec_instance_name_ids" {
  description = "Map of instance name to instance Id"
  value = merge(
    { for k, v in aws_instance.protected : k => v.id },
    { for k, v in aws_instance.standard : k => v.id },
  )
}

output "ec2_instance_private_ips" {
  description = "Map of instance name to private IP"
  value = merge(
    { for k, v in aws_instance.protected : k => v.private_ip },
    { for k, v in aws_instance.standard : k => v.private_ip }
  )
}