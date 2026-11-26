### Which Terminal Runs Which Command?

* **PC / Laptop Terminal (`~/.ssh/config`, `ssh-keygen`, `ssh`, `scp`, `scp -3`):** Runs on your local machine so OpenSSH uses `ProxyCommand` with `aws ssm start-session` to tunnel traffic over SSM without opening inbound port `22` or needing a public IP.


* **EC2 Instance Terminal (`/home/ubuntu` & `sudo`):** Runs inside the EC2 shell (`aws ssm start-session`) to inspect `ssh.service` / `ssh.socket`, append the public key to `/home/ubuntu/.ssh/authorized_keys`, unpack `fake-service`, and configure `systemd` services.


* **Important note on the uploaded image:** In the screenshot, `ssh.service` shows `inactive (dead)` while `ssh.socket` shows `active (running)` listening on port `22` (`0.0.0.0:22` and `[::]:22`). Because `ssh.socket` uses socket activation, systemd starts `sshd` automatically when an SSH connection arrives on port `22`, so `inactive (dead)` before connecting is normal as long as `ssh.socket` is `active (listening)`.

---

```markdown
# AWS SSM Session Manager, SSH Tunneling & Multi-Tier Private EC2 Guide

## Where Each Command Runs
* **PC / Laptop Terminal:** Edit `~/.ssh/config`, generate SSH keys (`ssh-keygen`), run `ssh`, and run `scp` / `scp -3` file transfers[cite: 11].
* **EC2 Terminal (`/home/ubuntu`):** Check `ssh.socket` / `ssh.service`, add the public key to `/home/ubuntu/.ssh/authorized_keys`, unpack `fake-service`, and configure `systemd` services[cite: 11].

---

## Prerequisites & Setup

### Install SessionManager Plugin on Your Laptop (PC Terminal)
Reference:
```text
[https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-macos-overview.html](https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-macos-overview.html)

```

Download, install, symlink, and remove the installer package:

```bash
curl "[https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/session-manager-plugin.pkg](https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/session-manager-plugin.pkg)" -o "session-manager-plugin.pkg"

sudo installer -pkg session-manager-plugin.pkg -target /

sudo ln -s /usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/session-manager-plugin

rm -rf session-manager-plugin.pkg

```

### Terraform Outputs

```hcl
Outputs:

instance_ids = {
  "instance01" = "i-07aa0a8973dded801"
  "instance02" = "i-07ffcc9094d7b9261"
  "instance03" = "i-0d86f3750cd6d5bbc"
}
session_manager_commands = {
  "instance01" = "aws ssm start-session --target i-07aa0a8973dded801"
  "instance02" = "aws ssm start-session --target i-07ffcc9094d7b9261"
  "instance03" = "aws ssm start-session --target i-0d86f3750cd6d5bbc"
}
session_manager_role_arn = "arn:aws:iam::904464083807:role/frontend-session-manager-role"
vpc_endpoints = {
  "ec2_messages" = "vpce-05ac47ad098e279fd"
  "ssm" = "vpce-04a1b709df787ec24"
  "ssm_messages" = "vpce-0b405c06345133e56"
}

```

> **Note:** Always pass `--region ap-southeast-1` (or your instance's region) when `--region` is not set as your default AWS CLI region, and never pass `/` or a trailing slash after `--region`.
> ```bash
> aws ssm start-session --target i-07aa0a8973dded801 --region ap-southeast-1
> 
> ```
> 
> 

---

## Step 1: Allow SSH Connections via Session Manager Tunnel (PC Terminal)

Configure `~/.ssh/config` on your PC/laptop so `ssh` and `scp` to `i-*` instances tunnel through AWS Systems Manager Session Manager (`AWS-StartSSHSession`):

```bash
vi ~/.ssh/config

```

Add the following configuration (update `--region` and `--profile` if needed for your environment):

```sshconfig
Host i-*
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --region ap-southeast-1"

```

---

## Step 2: Connect via SSM & Check SSH Server on EC2 (EC2 Terminal)

### 1. Start SSM Session to EC2-1 (`customer-profile-svc`) & EC2-2 (`account-svc`)

Run from your **PC terminal** (in separate terminal tabs or sessions):

```bash
aws ssm start-session --target i-07aa0a8973dded801 --region ap-southeast-1

```

```bash
aws ssm start-session --target i-07ffcc9094d7b9261 --region ap-southeast-1

```

### 2. Check SSH Socket & Service Inside Both EC2 Instances (EC2 Terminal)

Run inside both `instance01` (`i-07aa0a8973dded801`) and `instance02` (`i-07ffcc9094d7b9261`):

```bash
sudo systemctl status ssh.socket
sudo systemctl status ssh

```

`ssh.socket` should be `active (listening)` on port `22`. `ssh.service` may appear `inactive (dead)` until a socket connection triggers `sshd`.

Check each instance's private IP from inside its EC2 terminal:

```bash
hostname -I
# EC2-1 example: 10.0.253.230
# EC2-2 example: 10.0.254.254

```

---

## Step 3: Generate SSH Key & Authorize Public Key on Both EC2 Instances

### 1. Generate SSH Key Pair (PC Terminal)

Run on your **PC terminal** (for example in your project/working directory):

```bash
ssh-keygen -t ed25519 -f ./ssm-ec2-key -C "ssm-ec2-demo"
ls -l ./ssm-ec2-key*
cat ./ssm-ec2-key.pub

```

Example public key format:

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ssm-ec2-demo

```

### 2. Add Public Key to `authorized_keys` on Both EC2 Instances (EC2 Terminal `/home/ubuntu`)

Run inside **both** `instance01` and `instance02` EC2 terminals:

```bash
sudo su - ubuntu
cd /home/ubuntu
mkdir -p ~/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ssm-ec2-demo" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

```

---

## Step 4: Test SSH & Copy Files (`scp` and `scp -3`)

### 1. Test SSH Over SSM Tunnel (PC Terminal)

```bash
ssh -i ./ssm-ec2-key ubuntu@i-07aa0a8973dded801

```

### 2. Copy `fake_service_linux_amd64.zip` from PC to EC2-1 `/home/ubuntu/` (PC Terminal)

```bash
scp -i ./ssm-ec2-key ./fake_service_linux_amd64.zip ubuntu@i-07aa0a8973dded801:/home/ubuntu/

```

Verify the file in `/home/ubuntu/` on EC2-1 (**EC2 Terminal**):

```bash
sudo ls -la /home/ubuntu/

```

### 3. Copy `fake_service_linux_amd64.zip` from EC2-1 to EC2-2 Using `scp -3` (PC Terminal)

`-3` transfers the file through your local PC terminal between the two remote hosts without leaving a copy saved on your PC disk:

```bash
scp -3 -i ./ssm-ec2-key \
  ubuntu@i-07aa0a8973dded801:/home/ubuntu/fake_service_linux_amd64.zip \
  ubuntu@i-07ffcc9094d7b9261:/home/ubuntu/

```

Verify the file in `/home/ubuntu/` on EC2-2 (**EC2 Terminal**):

```bash
sudo ls -la /home/ubuntu/

```

---

## Step 5: Unpack Binary & Configure Systemd Services (EC2 Terminal)

### 1. Unpack `fake-service` in `/home/ubuntu` (Run on Both EC2-1 and EC2-2)

```bash
sudo su - ubuntu
cd /home/ubuntu
python3 -m zipfile -e fake_service_linux_amd64.zip .
chmod +x fake-service
sudo mv fake-service /usr/local/bin/fake-service

```

### 2. Configure Upstream Service (`account.service`) on EC2-2 (`10.0.254.254`)

```bash
sudo tee /etc/systemd/system/account.service > /dev/null << 'EOF'
[Unit]
Description=Account Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/fake-service
Environment=LISTEN_ADDR=0.0.0.0:9092
Environment=NAME=account-svc
Environment="MESSAGE=HelloCloudBank | Retail Banking | account-svc"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable account.service
sudo systemctl start account.service
sudo systemctl status account.service

```

### 3. Configure Downstream Service (`customer-profile.service`) on EC2-1 (`10.0.253.230`)

```bash
sudo tee /etc/systemd/system/customer-profile.service > /dev/null << 'EOF'
[Unit]
Description=Customer Profile Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/fake-service
Environment=LISTEN_ADDR=0.0.0.0:9091
Environment=NAME=customer-profile-svc
Environment="MESSAGE=HelloCloudBank | Retail Banking | customer-profile-svc"
Environment=UPSTREAM_URIS=[http://10.0.254.254:9092](http://10.0.254.254:9092)
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable customer-profile.service
sudo systemctl start customer-profile.service
sudo systemctl status customer-profile.service

```

---

## Step 6: Security Group Rules (Least Privilege)

Configure `frontend-session-manager-sg` (`sg-02f6d19b7953959b5`) so EC2-1 can reach EC2-2 on port `9092` while keeping SSM VPC endpoints functional:

### Inbound Rules

| Type | Protocol | Port Range | Source | Purpose |
| --- | --- | --- | --- | --- |
| Custom TCP | TCP | `9092` | `10.0.253.230/32` | Allow EC2-1 (`customer-profile-svc`) to call EC2-2 (`account-svc`) |

Ensure the Source IP for port `9092` is EC2-1's private IP (`10.0.253.230/32`), not EC2-2's own IP, and remove unused extra rules such as port `9091` inbound.

### Outbound Rules

| Type | Protocol | Port Range | Destination | Purpose |
| --- | --- | --- | --- | --- |
| HTTPS | TCP | `443` | `sg-02fbb5729f8632cbc` (`frontend-vpc-endpoint-sg`) | Required for AWS SSM Session Manager VPC endpoints |
| Custom TCP | TCP | `9092` | `10.0.254.254/32` | Allow EC2-1 outbound traffic to EC2-2 (`account-svc`) |

---

## Step 7: Verification & End-to-End Testing (EC2 Terminal)

### 1. Test Cross-EC2 Connectivity from EC2-1 (`10.0.253.230`) to EC2-2 (`9092`)

```bash
curl -i http://10.0.254.254:9092

```

### 2. End-to-End Downstream + Upstream Test on EC2-1 (`9091`)

```bash
curl -i http://127.0.0.1:9091

```

```

```