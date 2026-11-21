# ⚡ Quick Reference Guide

## One-Liner Commands

```bash
# Full deployment from scratch
make demo-setup

# Check current deployment
make demo-info

# Tear down
make demo-destroy
```

## Project Architecture

```
Your Computer        AWS                    EC2 Instance
─────────────       ───                    ────────────
  .ssh/              [Internet]              Ubuntu
 ├─ id_ed25519 ───→ Security Group  ──→     ├─ nginx
 └─ id_ed25519.pub  │ SSH: :22             └─ index.html
                    │ HTTP: :80             
Terraform ────→ Create Resources           
                   EC2 Instance ───→ [Public IP]
Ansible  ────────→ [SSH] ──────────────→ Configure
```

## Command Cheatsheet

| Task | Command |
|------|---------|
| **Quick Start** | `make demo-setup` |
| Show help | `make help` |
| Check code (no AWS) | `make local-test` |
| **Terraform Only** | |
| Validate syntax | `make tf-validate` |
| See what will be created | `make tf-plan` |
| Create instance | `make tf-apply` |
| Delete instance | `make tf-destroy` |
| **Ansible Only** | |
| Check playbook syntax | `make ansible-check` |
| Install nginx | `make ansible-run` |
| **Info** | |
| Show deployment details | `make demo-info` |
| Show deployment status | `make demo-status` |
| **Cleanup** | |
| Remove temp files | `make clean` |
| Delete everything | `make demo-destroy` |

## Key Files

| File | Purpose | Edit? |
|------|---------|-------|
| `terraform/main.tf` | Create EC2, security group | Yes - try changing instance_type |
| `terraform/variables.tf` | Input variables | No - reference only |
| `terraform/outputs.tf` | What to display after deploy | No - reference only |
| `ansible/playbook.yml` | Install nginx | Yes - try changing HTML content |
| `Makefile` | Automation commands | Reference only |
| `README.md` | Full documentation | Reference only |
| `DEMO.md` | Classroom demo guide | Reference only |

## Workflow

```
1. make local-test
   ↓
   Code looks good ✓
   ↓
2. make tf-plan
   ↓
   Changes look right ✓
   ↓
3. make tf-apply
   ↓
   Instance created + inventory.ini written
   ↓
4. make ansible-run
   ↓
   nginx is installed and running ✓
   ↓
5. make demo-info
   ↓
   Get the URL and visit it in browser ✓
   ↓
6. make demo-destroy
   ↓
   Clean up AWS resources
```

## Terraform Data Flow

```
variables.tf
     ↓
main.tf ──→ AWS API ──→ EC2 Instance
     ↓                    Security Group
outputs.tf              Key Pair
     ↓
terraform.tfstate (local state file)
     ↓
Write: ansible/inventory.ini (dynamic)
```

## Ansible Data Flow

```
playbook.yml ──┐
               ├──→ Ansible Controller ──→ SSH ──→ EC2 Instance
inventory.ini ─┘
     ↓
   .yaml template → Render → Deploy
                     ↓
                 host variables
```

## Important Paths

```bash
~/.ssh/id_ed25519       # Your SSH private key (SECRET!)
~/.ssh/id_ed25519.pub   # Your SSH public key (safe to share)
terraform/.terraform/   # Terraform plugins (auto-downloaded)
terraform/terraform.tfstate   # Current state (DON'T commit!)
ansible/inventory.ini   # Host list (auto-generated)
```

## Troubleshooting Quick Fixes

| Problem | Fix |
|---------|-----|
| Terraform command not found | `brew install terraform` |
| Ansible command not found | `pip install ansible` |
| AWS credentials error | `aws configure` |
| SSH timeout | Wait 2 minutes, then retry |
| Ansible can't find inventory | Run `make tf-apply` first |
| Unclear which IP to use | `make demo-info` shows everything |

## AWS Console Shortcuts

While demo is running, check AWS Console:

- **EC2 Instances**: See your instance starting
- **Security Groups**: View firewall rules
- **Key Pairs**: See your SSH key uploaded
- **Network Interfaces**: View IP addresses
- **CloudWatch**: Watch logs (advanced)

Access at: https://console.aws.amazon.com/

## Idempotency Examples

The beauty of IaC:

```bash
# Run these commands multiple times - same result
make local-test      # Always passes (no changes)
make ansible-run     # Second run: "changed=0" (no work needed)
terraform plan       # Shows no differences
```

**This means:** Safe to re-run if unsure!

## Costs

| Resource | Free Tier | Beyond |
|----------|-----------|--------|
| EC2 t3.micro | 750 hrs/month | ~$0.01/hr |
| Data transfer | First 1GB/month | $0.09/GB |
| **Total** | **~750 hrs free** | **~$7-10/month** |

**Always** run `make demo-destroy` after the demo!

## Common Customizations

### Change instance size
Edit `terraform/variables.tf`:
```hcl
default = "t3.small"  # Instead of t3.micro
```

### Change region
Edit `terraform/variables.tf`:
```hcl
default = "us-east-1"  # Instead of eu-west-2
```

### Change the web page
Edit `ansible/playbook.yml` in the "Deploy a simple index page" task:
```yaml
content: |
  <!DOCTYPE html>
  <html>
    <body>
      <h1>Your custom message here!</h1>
    </body>
  </html>
```

Then: `make ansible-run`

### Add more packages
Edit `ansible/playbook.yml` - add under `tasks:`:
```yaml
- name: Install curl and git
  ansible.builtin.apt:
    name: [curl, git]
    state: present
    update_cache: true
```

Then: `make ansible-run`

## Useful AWS CLI Commands

```bash
# Check AWS credential
aws sts get-caller-identity

# Get your public IP
curl https://checkip.amazonaws.com

# List your EC2 instances
aws ec2 describe-instances --region eu-west-2

# Get instance details
aws ec2 describe-instances \
  --instance-ids i-0123456789abcdef0 \
  --region eu-west-2
```

---

Need more? See [README.md](README.md) or [DEMO.md](DEMO.md) 📖
