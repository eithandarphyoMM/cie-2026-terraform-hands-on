################################################################################
# customer_profile_vpc
# Reference: https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/main.tf
# Reference: https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/variables.tf
################################################################################
module "customer_profile_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3" # pin to exact version - HashiCorp Recommendation

  providers = {
    aws = aws.singapore
  }

  name = var.customer_profile_vpc_name
  cidr = var.customer_profile_vpc_cidr
  azs  = var.customer_profile_vpc_azs

  public_subnets       = var.customer_profile_vpc_public_subnets
  public_subnet_names  = var.customer_profile_vpc_public_subnet_names
  private_subnets      = var.customer_profile_vpc_private_subnets
  private_subnet_names = var.customer_profile_vpc_private_subnet_names

  create_igw = true
  igw_tags = {
    Name = var.customer_profile_igw_name
  }

  public_route_table_tags = {
    Name = var.customer_profile_public_rtb_name
  }

  private_route_table_tags = {
    Name = var.customer_profile_private_rtb_name
  }

  # Keep NAT gateway disabled so only customer_profile_igw handles public subnet internet access
  enable_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.customer_profile_vpc_name
  }
}

################################################################################
# account_vpc
# Reference: https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/main.tf
# Reference: https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/variables.tf
################################################################################
module "account_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3" # pin to exact version - HashiCorp Recommendation

  providers = {
    aws = aws.singapore
  }

  name = var.account_vpc_name
  cidr = var.account_vpc_cidr
  azs  = var.account_vpc_azs

  private_subnets      = var.account_vpc_private_subnets
  private_subnet_names = var.account_vpc_private_subnet_names
  create_igw           = false

  private_route_table_tags = {
    Name = var.account_private_rtb_name
  }

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.account_vpc_name
  }
}

################################################################################
# statement_vpc
# Reference: https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/main.tf
# Reference: https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/variables.tf
################################################################################
module "statement_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3" # pin to exact version - HashiCorp Recommendation

  providers = {
    aws = aws.singapore
  }

  name = var.statement_vpc_name
  cidr = var.statement_vpc_cidr
  azs  = var.statement_vpc_azs

  private_subnets      = var.statement_vpc_private_subnets
  private_subnet_names = var.statement_vpc_private_subnet_names
  create_igw           = false

  private_route_table_tags = {
    Name = var.statement_private_rtb_name
  }

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.statement_vpc_name
  }
}

################################################################################
# Explicit Subnet Name Tags (Guarantees Exact Names on Existing Subnets)
################################################################################
resource "aws_ec2_tag" "customer_profile_public_subnet_names" {
  provider    = aws.singapore
  count       = length(module.customer_profile_vpc.public_subnets)
  resource_id = module.customer_profile_vpc.public_subnets[count.index]
  key         = "Name"
  value       = var.customer_profile_vpc_public_subnet_names[count.index]
}

resource "aws_ec2_tag" "customer_profile_private_subnet_names" {
  provider    = aws.singapore
  count       = length(module.customer_profile_vpc.private_subnets)
  resource_id = module.customer_profile_vpc.private_subnets[count.index]
  key         = "Name"
  value       = var.customer_profile_vpc_private_subnet_names[count.index]
}

resource "aws_ec2_tag" "account_private_subnet_names" {
  provider    = aws.singapore
  count       = length(module.account_vpc.private_subnets)
  resource_id = module.account_vpc.private_subnets[count.index]
  key         = "Name"
  value       = var.account_vpc_private_subnet_names[count.index]
}

resource "aws_ec2_tag" "statement_private_subnet_names" {
  provider    = aws.singapore
  count       = length(module.statement_vpc.private_subnets)
  resource_id = module.statement_vpc.private_subnets[count.index]
  key         = "Name"
  value       = var.statement_vpc_private_subnet_names[count.index]
}

################################################################################
# VPC Peering: customer_profile_vpc <-> account_vpc
################################################################################
resource "aws_vpc_peering_connection" "customer_profile_vpc_to_account_vpc" {
  provider    = aws.singapore
  vpc_id      = module.customer_profile_vpc.vpc_id
  peer_vpc_id = module.account_vpc.vpc_id
  auto_accept = true

  tags = {
    Name = var.customer_profile_vpc_peering_name
  }
}

resource "aws_route" "customer_profile_vpc_private_to_account_vpc" {
  provider                  = aws.singapore
  count                     = length(module.customer_profile_vpc.private_route_table_ids)
  route_table_id            = module.customer_profile_vpc.private_route_table_ids[count.index]
  destination_cidr_block    = var.account_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.customer_profile_vpc_to_account_vpc.id
}

resource "aws_route" "account_vpc_private_to_customer_profile_vpc" {
  provider                  = aws.singapore
  count                     = length(module.account_vpc.private_route_table_ids)
  route_table_id            = module.account_vpc.private_route_table_ids[count.index]
  destination_cidr_block    = var.customer_profile_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.customer_profile_vpc_to_account_vpc.id
}

################################################################################
# VPC Peering: account_vpc <-> statement_vpc
################################################################################
resource "aws_vpc_peering_connection" "account_vpc_to_statement_vpc" {
  provider    = aws.singapore
  vpc_id      = module.account_vpc.vpc_id
  peer_vpc_id = module.statement_vpc.vpc_id
  auto_accept = true

  tags = {
    Name = var.account_vpc_peering_name
  }
}

resource "aws_route" "account_vpc_private_to_statement_vpc" {
  provider                  = aws.singapore
  count                     = length(module.account_vpc.private_route_table_ids)
  route_table_id            = module.account_vpc.private_route_table_ids[count.index]
  destination_cidr_block    = var.statement_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.account_vpc_to_statement_vpc.id
}

resource "aws_route" "statement_vpc_private_to_account_vpc" {
  provider                  = aws.singapore
  count                     = length(module.statement_vpc.private_route_table_ids)
  route_table_id            = module.statement_vpc.private_route_table_ids[count.index]
  destination_cidr_block    = var.account_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.account_vpc_to_statement_vpc.id
}

################################################################################
# Security Groups via terraform-aws-modules/security-group/aws (No Inline Rules)
# Reference: https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/main.tf
# Reference: https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/variables.tf
################################################################################
module "bastion_host_sgp" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  providers = {
    aws = aws.singapore
  }

  name            = var.bastion_host_sgp_name
  use_name_prefix = false
  description     = "Allow SSH into bastion_host in customer_profile_vpc"
  vpc_id          = module.customer_profile_vpc.vpc_id

  ingress_rules = {
    ssh-from-allowed-cidr = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = var.ssh_allowed_cidr
      description = "SSH from allowed CIDR"
    }
  }

  egress_rules = {
    ssh-to-customer-profile-vpc = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = var.customer_profile_vpc_cidr
      description = "SSH to customer_profile EC2 in customer_profile_vpc"
    }
    http-outbound = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Outbound HTTP for package/tool downloads"
    }
    https-outbound = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Outbound HTTPS for package/tool downloads"
    }
  }

  tags = {
    Name = var.bastion_host_sgp_name
  }
}

module "customer_profile_private_instance_sgp" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  providers = {
    aws = aws.singapore
  }

  name            = var.customer_profile_private_instance_sgp_name
  use_name_prefix = false
  description     = "Restrict customer_profile EC2 to ALB port 9091, bastion SSH, and account_vpc"
  vpc_id          = module.customer_profile_vpc.vpc_id

  ingress_rules = {
    http-from-alb-9091 = {
      from_port                    = 9091
      to_port                      = 9091
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.customer_profile_alb.security_group_id
      description                  = "HTTP from customer-profile-alb on port 9091"
    }
    ssh-from-bastion = {
      from_port                    = 22
      to_port                      = 22
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.bastion_host_sgp.id
      description                  = "SSH from bastion_host"
    }
  }

  egress_rules = {
    http-to-account-vpc = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_vpc_cidr
      description = "Call account-alb on port 80 over peering"
    }
    ssh-to-account-vpc = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_vpc_cidr
      description = "Copy fake-service binary via SCP/SSH to account EC2 over peering"
    }
  }

  tags = {
    Name = var.customer_profile_private_instance_sgp_name
  }
}

module "account_private_instance_sgp" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  providers = {
    aws = aws.singapore
  }

  name            = var.account_private_instance_sgp_name
  use_name_prefix = false
  description     = "Restrict account EC2 to account-alb, customer_profile_vpc SSH/SCP, and statement_vpc"
  vpc_id          = module.account_vpc.vpc_id

  ingress_rules = {
    http-from-account-alb-9092 = {
      from_port                    = 9092
      to_port                      = 9092
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.account_alb.security_group_id
      description                  = "HTTP from account-alb on port 9092"
    }
    ssh-from-customer-profile-vpc = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = var.customer_profile_vpc_cidr
      description = "SSH/SCP from customer_profile_vpc over peering"
    }
  }

  egress_rules = {
    http-to-statement-vpc = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = var.statement_vpc_cidr
      description = "Call statement-alb on port 80 over peering"
    }
    ssh-to-statement-vpc = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = var.statement_vpc_cidr
      description = "Copy fake-service binary via SCP/SSH to statement EC2 over peering"
    }
  }

  tags = {
    Name = var.account_private_instance_sgp_name
  }
}

module "statement_instance_sgp" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  providers = {
    aws = aws.singapore
  }

  name            = var.statement_instance_sgp_name
  use_name_prefix = false
  description     = "Restrict statement EC2 to statement-alb and account_vpc SSH/SCP"
  vpc_id          = module.statement_vpc.vpc_id

  ingress_rules = {
    http-from-statement-alb-9093 = {
      from_port                    = 9093
      to_port                      = 9093
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.statement_alb.security_group_id
      description                  = "HTTP from statement-alb on port 9093"
    }
    ssh-from-account-vpc = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_vpc_cidr
      description = "SSH/SCP from account_vpc over peering"
    }
  }

  egress_rules = {
    local-vpc-only = {
      from_port   = 0
      to_port     = 0
      ip_protocol = "-1"
      cidr_ipv4   = var.statement_vpc_cidr
      description = "Restrict outbound traffic to statement_vpc CIDR only"
    }
  }

  tags = {
    Name = var.statement_instance_sgp_name
  }
}

################################################################################
# Application Load Balancers & Target Groups via terraform-aws-modules/alb/aws
# Reference: https://github.com/terraform-aws-modules/terraform-aws-alb/blob/master/main.tf
# Reference: https://github.com/terraform-aws-modules/terraform-aws-alb/blob/master/variables.tf
################################################################################
module "customer_profile_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.2.0"

  providers = {
    aws = aws.singapore
  }

  name                       = var.customer_profile_alb_name
  load_balancer_type         = "application"
  internal                   = false
  vpc_id                     = module.customer_profile_vpc.vpc_id
  subnets                    = module.customer_profile_vpc.public_subnets
  enable_deletion_protection = false

  security_group_name = var.customer_profile_alb_sgp_name
  security_group_ingress_rules = {
    http-from-internet = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTP from internet"
    }
  }
  security_group_egress_rules = {
    forward-to-customer-profile-9091 = {
      from_port   = 9091
      to_port     = 9091
      ip_protocol = "tcp"
      cidr_ipv4   = var.customer_profile_vpc_cidr
      description = "Forward to customer_profile fake-service port 9091"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = var.customer_profile_tgp_name
      }
    }
  }

  target_groups = {
    (var.customer_profile_tgp_name) = {
      name              = var.customer_profile_tgp_name
      protocol          = "HTTP"
      port              = 9091
      target_type       = "instance"
      create_attachment = false
      health_check = {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  }

  tags = {
    Name = var.customer_profile_alb_name
  }
}

module "account_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.2.0"

  providers = {
    aws = aws.singapore
  }

  name                       = var.account_alb_name
  load_balancer_type         = "application"
  internal                   = true
  vpc_id                     = module.account_vpc.vpc_id
  subnets                    = module.account_vpc.private_subnets
  enable_deletion_protection = false

  security_group_name = var.account_alb_sgp_name
  security_group_ingress_rules = {
    http-from-customer-profile-vpc = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = var.customer_profile_vpc_cidr
      description = "HTTP from customer_profile_vpc"
    }
  }
  security_group_egress_rules = {
    forward-to-account-9092 = {
      from_port   = 9092
      to_port     = 9092
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_vpc_cidr
      description = "Forward to account EC2 fake-service port 9092"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = var.account_tgp_name
      }
    }
  }

  target_groups = {
    (var.account_tgp_name) = {
      name              = var.account_tgp_name
      protocol          = "HTTP"
      port              = 9092
      target_type       = "instance"
      create_attachment = false
      health_check = {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  }

  tags = {
    Name = var.account_alb_name
  }
}

module "statement_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.2.0"

  providers = {
    aws = aws.singapore
  }

  name                       = var.statement_alb_name
  load_balancer_type         = "application"
  internal                   = true
  vpc_id                     = module.statement_vpc.vpc_id
  subnets                    = module.statement_vpc.private_subnets
  enable_deletion_protection = false

  security_group_name = var.statement_alb_sgp_name
  security_group_ingress_rules = {
    http-from-account-vpc = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = var.account_vpc_cidr
      description = "HTTP from account_vpc"
    }
  }
  security_group_egress_rules = {
    forward-to-statement-9093 = {
      from_port   = 9093
      to_port     = 9093
      ip_protocol = "tcp"
      cidr_ipv4   = var.statement_vpc_cidr
      description = "Forward to statement EC2 fake-service port 9093"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = var.statement_tgp_name
      }
    }
  }

  target_groups = {
    (var.statement_tgp_name) = {
      name              = var.statement_tgp_name
      protocol          = "HTTP"
      port              = 9093
      target_type       = "instance"
      create_attachment = false
      health_check = {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  }

  tags = {
    Name = var.statement_alb_name
  }
}

################################################################################
# EC2 Instances via terraform-aws-modules/ec2-instance/aws & TG Attachments
# Reference: https://github.com/terraform-aws-modules/terraform-aws-ec2-instance/blob/master/main.tf
# Reference: https://github.com/terraform-aws-modules/terraform-aws-ec2-instance/blob/master/variables.tf
################################################################################
module "bastion_host" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.1"

  providers = {
    aws = aws.singapore
  }

  name                        = var.bastion_host_name
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.bastion_host_key_name
  subnet_id                   = module.customer_profile_vpc.public_subnets[0]
  vpc_security_group_ids      = [module.bastion_host_sgp.id]
  associate_public_ip_address = true
  create_security_group       = false

  tags = {
    Name = var.bastion_host_name
  }
}

module "customer_profile" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.1"

  providers = {
    aws = aws.singapore
  }

  name                   = var.customer_profile_instance_name
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.customer_profile_key_name
  subnet_id              = module.customer_profile_vpc.private_subnets[0]
  vpc_security_group_ids = [module.customer_profile_private_instance_sgp.id]
  create_security_group  = false

  tags = {
    Name = var.customer_profile_instance_name
  }
}

module "account" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.1"

  providers = {
    aws = aws.singapore
  }

  name                   = var.account_instance_name
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.account_key_name
  subnet_id              = module.account_vpc.private_subnets[0]
  vpc_security_group_ids = [module.account_private_instance_sgp.id]
  create_security_group  = false

  tags = {
    Name = var.account_instance_name
  }
}

module "statement" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.1"

  providers = {
    aws = aws.singapore
  }

  name                   = var.statement_instance_name
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.statement_key_name
  subnet_id              = module.statement_vpc.private_subnets[0]
  vpc_security_group_ids = [module.statement_instance_sgp.id]
  create_security_group  = false

  tags = {
    Name = var.statement_instance_name
  }
}

resource "aws_lb_target_group_attachment" "customer_profile_attachment" {
  provider         = aws.singapore
  target_group_arn = module.customer_profile_alb.target_groups[var.customer_profile_tgp_name].arn
  target_id        = module.customer_profile.id
  port             = 9091
}

resource "aws_lb_target_group_attachment" "account_attachment" {
  provider         = aws.singapore
  target_group_arn = module.account_alb.target_groups[var.account_tgp_name].arn
  target_id        = module.account.id
  port             = 9092
}

resource "aws_lb_target_group_attachment" "statement_attachment" {
  provider         = aws.singapore
  target_group_arn = module.statement_alb.target_groups[var.statement_tgp_name].arn
  target_id        = module.statement.id
  port             = 9093
}