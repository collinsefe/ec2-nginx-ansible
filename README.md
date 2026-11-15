# nginx on EC2 — Terraform + Ansible

```
nginx-ec2/
├── terraform/   # creates the EC2 instance, SG, key pair; writes ansible/inventory.ini
└── ansible/     # installs nginx and a test page
```

## Prerequisites
- Terraform >= 1.5, Ansible >= 2.14
- AWS credentials configured (`aws configure` / SSO / env vars)
- An SSH key pair (defaults to `~/.ssh/id_ed25519[.pub]`)

## 1. Provision the instance
```bash
cd terraform
terraform init
terraform apply -var="ssh_cidr=$(curl -s https://checkip.amazonaws.com)/32"
```
This also generates `../ansible/inventory.ini` with the instance's public IP.

## 2. Install nginx
```bash
cd ../ansible
ansible-playbook playbook.yml
```

## 3. Test
```bash
curl "$(terraform -chdir=../terraform output -raw url)"
```

## Tear down
```bash
cd ../terraform && terraform destroy -var="ssh_cidr=0.0.0.0/32"
```
