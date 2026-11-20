################################################################################
# Shared / Instance / Peering / ALB / Security Group Naming
################################################################################
variable "ami_id" {
  description = "AMI ID for EC2 instances in ap-southeast-1 (e.g., Ubuntu 24.04 LTS x86_64)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for bastion and fake-service nodes"
  type        = string
  default     = "t3.micro"
}

variable "bastion_host_name" {
  description = "Name for bastion_host EC2 instance"
  type        = string
  default     = "bastion_host"
}

variable "customer_profile_instance_name" {
  description = "Name for customer_profile EC2 instance"
  type        = string
  default     = "customer_profile"
}

variable "account_instance_name" {
  description = "Name for account EC2 instance"
  type        = string
  default     = "account"
}

variable "statement_instance_name" {
  description = "Name for statement EC2 instance"
  type        = string
  default     = "statement"
}

variable "bastion_host_key_name" {
  description = "EC2 Key Pair name for bastion_host in ap-southeast-1"
  type        = string
  default     = "bastion_host_key"
}

variable "customer_profile_key_name" {
  description = "EC2 Key Pair name for customer_profile EC2 in ap-southeast-1"
  type        = string
  default     = "customer_profile_key"
}

variable "account_key_name" {
  description = "EC2 Key Pair name for account EC2 in ap-southeast-1"
  type        = string
  default     = "account_key"
}

variable "statement_key_name" {
  description = "EC2 Key Pair name for statement EC2 in ap-southeast-1"
  type        = string
  default     = "statement_key"
}

variable "ssh_allowed_cidr" {
  description = "Your public IP CIDR allowed to SSH into bastion_host (e.g., 203.0.113.10/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "customer_profile_vpc_peering_name" {
  description = "Name tag for VPC peering between customer_profile_vpc and account_vpc"
  type        = string
  default     = "customer_profile_vpc-to-account_vpc-peering"
}

variable "account_vpc_peering_name" {
  description = "Name tag for VPC peering between account_vpc and statement_vpc"
  type        = string
  default     = "account_vpc-to-statement_vpc-peering"
}

variable "bastion_host_sgp_name" {
  description = "Security group name for bastion_host"
  type        = string
  default     = "bastion_host_sgp"
}

variable "customer_profile_alb_sgp_name" {
  description = "Security group name for customer-profile-alb"
  type        = string
  default     = "customer_profile_alb_sgp"
}

variable "customer_profile_private_instance_sgp_name" {
  description = "Security group name for customer_profile private EC2 instance"
  type        = string
  default     = "customer_profile_private_instance_sgp"
}

variable "account_alb_sgp_name" {
  description = "Security group name for account-alb"
  type        = string
  default     = "account_alb_sgp"
}

variable "account_private_instance_sgp_name" {
  description = "Security group name for account private EC2 instance"
  type        = string
  default     = "account_private_instance_sgp"
}

variable "statement_alb_sgp_name" {
  description = "Security group name for statement-alb"
  type        = string
  default     = "statement_alb_sgp"
}

variable "statement_instance_sgp_name" {
  description = "Security group name for statement EC2 instance"
  type        = string
  default     = "statement_instance_sgp"
}

variable "customer_profile_alb_name" {
  description = "Name for customer-profile ALB"
  type        = string
  default     = "customer-profile-alb"
}

variable "customer_profile_tgp_name" {
  description = "Name for customer-profile target group"
  type        = string
  default     = "customer-profile-tgp"
}

variable "account_alb_name" {
  description = "Name for account ALB"
  type        = string
  default     = "account-alb"
}

variable "account_tgp_name" {
  description = "Name for account target group"
  type        = string
  default     = "account-tgp"
}

variable "statement_alb_name" {
  description = "Name for statement ALB"
  type        = string
  default     = "statement-alb"
}

variable "statement_tgp_name" {
  description = "Name for statement target group"
  type        = string
  default     = "statement-tgp"
}

################################################################################
# customer_profile_vpc
################################################################################
variable "customer_profile_vpc_name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "customer_profile_igw_name" {
  description = "Name tag for Internet Gateway on customer_profile_vpc"
  type        = string
  default     = "customer_profile_igw"
}

variable "customer_profile_public_rtb_name" {
  description = "Name tag for public route table on customer_profile_vpc"
  type        = string
  default     = "customer_profile_public_rtb"
}

variable "customer_profile_private_rtb_name" {
  description = "Name tag for private route table on customer_profile_vpc"
  type        = string
  default     = "customer_profile_private_rtb"
}

variable "customer_profile_vpc_cidr" {
  description = "(Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id`"
  type        = string
  default     = "10.0.0.0/16"
}

variable "customer_profile_vpc_azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "customer_profile_vpc_public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "customer_profile_vpc_public_subnet_names" {
  description = "Explicit Name tags for customer_profile_vpc public subnets"
  type        = list(string)
  default     = []
}

variable "customer_profile_vpc_private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "customer_profile_vpc_private_subnet_names" {
  description = "Explicit Name tags for customer_profile_vpc private subnets"
  type        = list(string)
  default     = []
}

################################################################################
# account_vpc
################################################################################
variable "account_vpc_name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "account_private_rtb_name" {
  description = "Name tag for private route table on account_vpc"
  type        = string
  default     = "account_private_rtb"
}

variable "account_vpc_cidr" {
  description = "(Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id`"
  type        = string
  default     = "172.16.0.0/16"
}

variable "account_vpc_azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "account_vpc_private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "account_vpc_private_subnet_names" {
  description = "Explicit Name tags for account_vpc private subnets"
  type        = list(string)
  default     = []
}

################################################################################
# statement_vpc
################################################################################
variable "statement_vpc_name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "statement_private_rtb_name" {
  description = "Name tag for private route table on statement_vpc"
  type        = string
  default     = "statement_private_rtb"
}

variable "statement_vpc_cidr" {
  description = "(Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id`"
  type        = string
  default     = "192.168.0.0/16"
}

variable "statement_vpc_azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "statement_vpc_private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "statement_vpc_private_subnet_names" {
  description = "Explicit Name tags for statement_vpc private subnets"
  type        = list(string)
  default     = []
}