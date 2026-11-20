output "customer_profile_alb_dns_name" {
  description = "Internet-facing DNS name for customer-profile-alb"
  value       = module.customer_profile_alb.dns_name
}

output "account_alb_dns_name" {
  description = "Internal DNS name for account-alb"
  value       = module.account_alb.dns_name
}

output "statement_alb_dns_name" {
  description = "Internal DNS name for statement-alb"
  value       = module.statement_alb.dns_name
}

output "bastion_host_public_ip" {
  description = "Public IP of bastion_host in customer_profile_vpc"
  value       = module.bastion_host.public_ip
}

output "customer_profile_private_ip" {
  description = "Private IP of customer_profile EC2"
  value       = module.customer_profile.private_ip
}

output "account_private_ip" {
  description = "Private IP of account EC2"
  value       = module.account.private_ip
}

output "statement_private_ip" {
  description = "Private IP of statement EC2"
  value       = module.statement.private_ip
}