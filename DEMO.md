# 🚀 Classroom Demo: Deploying nginx with Terraform & Ansible

This guide walks through a complete demo of Infrastructure as Code (IaC) and Configuration Management in a classroom setting. Perfect for beginners!

## What You'll Learn

- **Terraform**: Provision infrastructure (create an EC2 instance)
- **Ansible**: Configure that infrastructure (install and run nginx)
- **Infrastructure as Code**: Manage cloud resources with code, not clicking buttons
- **Cloud Networking**: Security groups, public IPs, SSH access
- **Automation**: One command deploys everything

---

## Prerequisites (Before Class)

### 1. Install Required Tools

```bash
# Install Terraform (if not already installed)
brew install terraform  # macOS
# or
sudo apt-get install terraform  # Linux

# Install Ansible
pip install ansible  # or: brew install ansible (macOS)

# Check versions
terraform version  # Should be >= 1.5
ansible --version  # Should be >= 2.14
```

### 2. Configure AWS Credentials

```bash
# Configure AWS CLI with your credentials
aws configure

# This asks for:
# AWS Access Key ID: [your key]
# AWS Secret Access Key: [your secret]
# Default region: eu-west-2  (or your preferred region)
# Default output format: json
```

**🔑 Security Note:** Keep your AWS credentials safe! Never commit them to git.

### 3. Generate SSH Keys (if needed)

```bash
# Generate Ed25519 keys (modern, secure)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Check they exist
ls -la ~/.ssh/id_ed25519*
```

---

## 🎓 Classroom Demo Flow

### Step 0: Show the Code (5 minutes)

Before deploying, walk through what we're deploying:

```bash
# Show the project structure
tree -L 2

# Key files to point out:
# - terraform/main.tf       → AWS resources (EC2, security group, key pair)
# - ansible/playbook.yml    → Configuration (install nginx)
# - Makefile               → Automation commands
```

**Talking Points:**
- Terraform = "Infrastructure as Code" (IaC)
- Ansible = "Configuration as Code" (CaC)
- Together = fully automated deployment from code
- No manual AWS Console clicking!

---

### Step 1: Validate Without AWS (5 minutes)

Run local tests first—no AWS resources created:

```bash
# Validate Terraform syntax
make tf-validate
# Output: "Success! The configuration is valid."

# Check Ansible playbook syntax
make ansible-check
# Output: "playbook.yml:1 syntax OK"

# Or run all validation at once
make local-test
# Output: "✅ All local tests passed!"
```

**Why This Matters:**

- Catches mistakes before spending money on AWS
- Shows that IaC = fast feedback
- In production, this runs in CI/CD pipelines

---

### Step 2: Show the Plan (5 minutes)

See what Terraform **will** create before applying:

```bash
# See the deployment plan
make tf-plan SSH_CIDR=$(curl -s https://checkip.amazonaws.com)/32
# Or manually:
terraform -chdir=terraform plan \
  -var="ssh_cidr=$(curl -s https://checkip.amazonaws.com)/32" \
  -lock=false
```

**Key Output to Point Out:**
```
# An example from the plan:
  + aws_instance.web
      + ami                           = "ami-0d1234567890abcdef"
      + instance_type                 = "t3.micro"
      + key_name                      = "nginx-demo-key"
      + associate_public_ip_address   = true
      + subnet_id                     = "subnet-0123456789abcdef0"
      + vpc_id                        = "vpc-0123456789abcdef0"

  + aws_security_group.web
      - ingress rules (SSH from your IP, HTTP from internet)
      - egress rules (all outbound traffic allowed)
```

**Talking Points:**
- `-` = will be created
- `~` = will be modified
- `-` = will be deleted
- `lock=false` = prevents AWS state locking (safe for demos)

---

### Step 3: Deploy! (10 minutes)

Create the actual AWS resources:

```bash
# Deploy the infrastructure
make tf-apply SSH_CIDR=$(curl -s https://checkip.amazonaws.com)/32
```

**What Happens:**
1. Terraform connects to AWS
2. Creates the EC2 instance (1-2 minutes)
3. Creates the security group
4. Uploads the SSH public key
5. Generates `ansible/inventory.ini` automatically

**Expected Output:**
```
aws_key_pair.this: Creating...
aws_key_pair.this: Creation complete after 1s [id=nginx-demo-key]

aws_security_group.web: Creating...
aws_security_group.web: Creation complete after 2s [id=sg-0123456789abcdef0]

aws_instance.web: Creating...
aws_instance.web: Still creating... [10s elapsed]
aws_instance.web: Still creating... [20s elapsed]
aws_instance.web: Still creating... [30s elapsed]
aws_instance.web: Creation complete after 45s [id=i-0123456789abcdef0]

local_file.inventory: Creating...
local_file.inventory: Creation complete after 0s

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

**🎯 Key Teaching Moments:**
- Show the AWS Console in a browser tab:
  - EC2 Instances → see your new instance starting
  - Security Groups → see the firewall rules
  - Key Pairs → see your SSH key was uploaded
- Explain: Terraform made all these AWS API calls automatically!

---

### Step 4: Wait for Instance (3 minutes)

The instance is created but still booting. While waiting:

**Show the inventory file that was auto-generated:**
```bash
cat ansible/inventory.ini
# Output:
# [web]
# 52.123.45.67 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519
```

**Talking Points:**
- Terraform created this file with the instance's actual IP
- Ansible uses this to know:
  - **Where** to connect (IP address)
  - **Who** to log in as (ubuntu user)
  - **How** to authenticate (SSH private key)
- This is dynamic! If we deleted and recreated, Terraform would update it.

---

### Step 5: Configure with Ansible (5 minutes)

Now that the instance is running, have Ansible configure it:

```bash
# Run the Ansible playbook
make ansible-run

# Or manually:
cd ansible
ansible-playbook -i inventory.ini playbook.yml
```

**What Happens:**
1. Ansible connects via SSH
2. Waits for cloud-init to finish (OS initialization)
3. Installs nginx package
4. Deploys a custom homepage
5. Starts the nginx service
6. Tests that nginx responds

**Expected Output:**
```
PLAY [Install and configure nginx] *******************

TASK [Wait for SSH to come up on the new instance] ***
ok: [52.123.45.67]

TASK [Wait for cloud-init to finish...] *
changed: [52.123.45.67]

TASK [Install nginx] ****
changed: [52.123.45.67]

TASK [Deploy a simple index page] *
changed: [52.123.45.67]

TASK [Ensure nginx is running and enabled at boot] **
changed: [52.123.45.67]

TASK [Check nginx responds locally] *
ok: [52.123.45.67]

PLAY RECAP **
52.123.45.67 : ok=6 changed=4 unreachable=0 failed=0
```

**🎯 Key Teaching Moments:**
- `changed=4` → Ansible made 4 changes
- `ok=1` → 1 task ran without changes
- `unreachable=0` → Network was fine
- `failed=0` → Everything worked!
- Run it again: `changed=0` → Idempotent! (safe to re-run)

---

### Step 6: Visit Your Website (5 minutes)

```bash
# Get the URL
make demo-info
# Or:
terraform -chdir=terraform output url

# Visit it in your browser:
# http://52.123.45.67
# or the DNS name shown in the output

# Or from the terminal:
curl $(terraform -chdir=terraform output -raw url)
```

**You should see:**
```html
<h1>Hello from ip-10-0-1-100</h1>
<p>Provisioned by Terraform, configured by Ansible.</p>
```

**🎉 You just deployed infrastructure with code!**

---

### Step 7: Explore the Instance (10 minutes - optional)

SSH into the instance:

```bash
# Get the IP
IP=$(terraform -chdir=terraform output -raw public_ip)

# SSH in
ssh -i ~/.ssh/id_ed25519 ubuntu@$IP

# Now you're on the instance! Look around:
ps aux | grep nginx         # See nginx processes
systemctl status nginx       # Check service status
cat /var/www/html/index.html # See the page we deployed
curl http://localhost       # Test locally
```

---

### Step 8: Cleanup (5 minutes)

Destroy everything to avoid AWS charges:

```bash
# Remove everything we created
make demo-destroy

# It will ask for confirmation. Type: destroy-demo
# This deletes:
# - EC2 instance
# - Security group
# - Key pair
# - Everything except the code!
```

**Talking Points:**
- Code stays! Infrastructure is gone.
- Run `make demo-setup` again anytime to recreate.
- This is the power of IaC: disposable infrastructure.

---

## 📝 Makefile Cheat Sheet

Here are the most useful commands for the demo:

| Command | What It Does |
|---------|------------|
| `make help` | Show all available commands |
| `make local-test` | Validate code locally (no AWS) |
| `make demo-setup` | Full deployment (provision + configure) |
| `make tf-plan` | Show what will be created |
| `make tf-apply` | Create EC2 instance |
| `make ansible-run` | Install nginx |
| `make demo-info` | Show deployment details |
| `make demo-destroy` | Delete everything |
| `make clean` | Clean up state files |

---

## 🎓 Discussion Points for Students

### Why Infrastructure as Code?

**Problem (without IaC):**
- System admin clicks buttons in AWS Console
- Hours to deploy
- Hard to reproduce
- Mistakes: "forgot to open port 80"
- Different versions on different environments

**Solution (with IaC):**
- Everyone uses the same code
- Deploy in minutes
- Reproducible and consistent
- Changes reviewed in git before applying
- Version control for infrastructure!

### Why Terraform + Ansible?

- **Terraform**: Creates infrastructure (the servers themselves)
- **Ansible**: Configures infrastructure (what software runs on them)
- **Together**: Complete automation

### Real-World Use Cases

- **Development**: Spin up test environments automatically
- **Staging**: Identical to production, but separate
- **Production**: Deploy with confidence using tested code
- **Disaster Recovery**: Recreate infrastructure from code
- **Cost Optimization**: Destroy unused resources automatically

### Security Considerations

- **SSH Key Only**: No passwords to guess
- **Security Groups**: Firewall rules as code
- **IMDSv2**: Prevents instance metadata leaks
- **Encrypted Storage**: Data at rest is protected
- **IAM**: (not shown here, but important for real deployments)

---

## 🔧 Troubleshooting

### "terraform command not found"
```bash
# Install Terraform
brew install terraform  # macOS
sudo apt-get install terraform  # Linux
terraform version  # Verify
```

### "ansible command not found"
```bash
# Install Ansible
pip install ansible
ansible --version  # Verify
```

### "AWS credentials not configured"
```bash
# Set up AWS credentials
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=eu-west-2
```

### "SSH timeout or connection refused"
- Wait longer (instance takes 1-2 minutes to boot)
- Check Security Group allows SSH from your IP
- Check you're using the correct SSH key file

### "terraform lock timeout"
- Wait a minute and retry
- Or use `make tf-plan` with `lock=false` flag

### "ansible unreachable"
- Confirm instance has public IP: `make demo-info`
- Check SSH works manually: `ssh -i ~/.ssh/id_ed25519 ubuntu@IP`
- Confirm security group allows SSH

---

## 📚 Further Learning

### Key Concepts to Review
1. **VPC (Virtual Private Cloud)**: Isolated network in AWS
2. **Subnet**: Subdivision of VPC with its own IP range
3. **Security Group**: Virtual firewall rules
4. **EC2 Instance**: Virtual machine in the cloud
5. **AMI**: Pre-built machine images
6. **SSH**: Secure remote login
7. **Idempotency**: Can run safely multiple times

### Try These Extensions
1. **Change the web page**: Edit `ansible/playbook.yml` and redeploy
2. **Add HTTPS**: Modify Terraform security group to allow port 443
3. **Multiple instances**: Change `instance_type` to t3.small and add more
4. **Different region**: Change `region` variable
5. **AutoScaling**: Deploy multiple instances behind a load balancer

### Documentation
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [AWS EC2 Guide](https://docs.aws.amazon.com/ec2/)

---

## ⚠️ Important: AWS Costs

This demo uses **t3.micro** instances, which are:
- ✅ Free tier eligible (12 months for new AWS accounts)
- ✅ ~$0.01/hour if no longer free tier
- ⚠️ **Always destroy** after the demo with `make demo-destroy`

**Cost Example:**
- Forgotten instance for 1 month = ~$7
- Always clean up! `make demo-destroy`

---

## 🎯 Demo Timing

| Step | Time | Activity |
|------|------|----------|
| 0. Show code | 5 min | Walk through project structure |
| 1. Validate | 5 min | `make local-test` |
| 2. Plan | 5 min | `make tf-plan` |
| 3. Deploy | 10 min | `make tf-apply` |
| 4. Wait | 3 min | Instance boots (show AWS Console) |
| 5. Configure | 5 min | `make ansible-run` |
| 6. Visit | 5 min | Open in browser |
| 7. Explore | 10 min | SSH into instance (optional) |
| 8. Cleanup | 5 min | `make demo-destroy` |
| **Total** | **~55 min** | Complete demo with discussion |

---

## 📧 Questions & Support

If something goes wrong:
1. Check the error message carefully—it usually says what's wrong
2. Run `make local-test` to check code syntax
3. Run `make demo-info` to see current state
4. Check AWS Console for resource details
5. Post the error in the class forum or ask in office hours

**Common fixes:**
- SSH timeout? Wait longer for instance to boot
- Ansible unreachable? Check AWS Console for instance IP
- Plan fails? Check AWS credentials with `aws sts get-caller-identity`
- Nothing changes on rerun? That's idempotency—it's working!

---

Good luck with your demo! 🚀
