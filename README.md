# Multi-VPC Peering & `fake-service` Lab (`ap-southeast-1`)

Terraform Infrastructure as Code (IaC) provisioning a 3-VPC chained microservice lab in **Asia Pacific (Singapore) (`ap-southeast-1`)** using `terraform-aws-modules` (`vpc`, `security-group`, `alb`, and `ec2-instance`) with non-inline security group rules and chained `fake-service` instances (`customer-profile-svc` → `account-svc` → `statement-svc`)[cite: 1, 2, 7, 14].

---

## Architecture Overview

```text
Internet ──▶ customer-profile-alb (Internet-facing, Port 80)
                  │
                  ▼ (Port 9091)
        customer_profile EC2 (10.0.100.x, customer_profile_vpc)
                  │  [VPC Peering: 10.0.0.0/16 <-> 172.16.0.0/16]
                  ▼ (Port 80 / SCP Port 22)
           account-alb (Internal, Port 80)
                  │
                  ▼ (Port 9092)
           account EC2 (172.16.100.x, account_vpc)
                  │  [VPC Peering: 172.16.0.0/16 <-> 192.168.0.0/16]
                  ▼ (Port 80 / SCP Port 22)
          statement-alb (Internal, Port 80)
                  │
                  ▼ (Port 9093)
          statement EC2 (192.168.100.x, statement_vpc)
```

- **Bastion Access:** `bastion_host` runs in `customer_profile_public_subnet1` (`customer_profile_igw` attached to public subnets) with SSH (`TCP 22`) allowed to `customer_profile` (`10.0.100.x`)[cite: 14, 15].
- **Security Groups (`terraform-aws-modules/security-group/aws` v6.0.0):** Configured via `ingress_rules` and `egress_rules` maps (no inline `ingress`/`egress` blocks)[cite: 14]:
  1. `bastion_host_sgp`[cite: 14]
  2. `customer_profile_alb_sgp`[cite: 14]
  3. `customer_profile_private_instance_sgp`[cite: 14]
  4. `account_alb_sgp`[cite: 14]
  5. `account_private_instance_sgp`[cite: 14]
  6. `statement_alb_sgp`[cite: 14]
  7. `statement_instance_sgp`[cite: 14]

---

## Project Structure

```text
.
├── providers.tf       # Terraform & AWS provider (alias = "singapore", ap-southeast-1)
├── variables.tf       # Input variables for VPCs, subnets, route tables, SGs, ALBs, EC2
├── terraform.tfvars   # Environment values and exact resource names
├── main.tf            # VPCs, peering & routes, SGs, ALBs/TGs, EC2 instances, subnet tags
├── outputs.tf         # ALB DNS names and EC2 IP addresses
└── README.md          # Lab documentation and runbook
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.5.0`
- [AWS CLI](https://docs.aws.amazon.com/cli/) configured with credentials for `ap-southeast-1`
- Existing EC2 Key Pairs in `ap-southeast-1` (`bastion_host_key`, `customer_profile_key`, `account_key`, `statement_key`)[cite: 11]
- A valid Ubuntu 24.04 LTS `x86_64` AMI ID in `ap-southeast-1` set in `terraform.tfvars`

---

## Quick Start

```zsh
terraform init -upgrade
terraform validate
terraform plan
terraform apply
```

### Verify Subnet & Route Table Naming

```zsh
aws ec2 describe-subnets \
  --region ap-southeast-1 \
  --query 'Subnets[*].[Tags[?Key==`Name`].Value | [0], SubnetId, VpcId, CidrBlock, AvailabilityZone]' \
  --output table
```

---

## Deploying & Running `fake-service`

Download `fake_service_linux_amd64.zip` from [`nicholasjackson/fake-service` releases](https://github.com/nicholasjackson/fake-service/releases), extract `fake-service`, copy it over SSH/SCP (`customer_profile` → `account` → `statement`), and start each service with its upstream ALB URL:

1. **On `statement` (`192.168.100.x`, Port `9093`):**
   ```bash
   chmod +x ./fake-service
   LISTEN_ADDR=0.0.0.0:9093 NAME=statement-svc ./fake-service
   ```
2. **On `account` (`172.16.100.x`, Port `9092`):**
   ```bash
   chmod +x ./fake-service
   LISTEN_ADDR=0.0.0.0:9092 NAME=account-svc UPSTREAM_URIS="http://<statement-alb-dns-name>" ./fake-service
   ```
3. **On `customer_profile` (`10.0.100.x`, Port `9091`):**
   ```bash
   chmod +x ./fake-service
   LISTEN_ADDR=0.0.0.0:9091 NAME=customer-profile-svc UPSTREAM_URIS="http://<account-alb-dns-name>" ./fake-service
   ```

Open `http://<customer-profile-alb-dns-name>/ui/` in your browser to inspect the `customer-profile-svc` → `account-svc` → `statement-svc` topology[cite: 1].

---

## Cleanup

```zsh
terraform destroy
```