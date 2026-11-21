# 🎓 Manual Ansible Training Guide (Session 1)

**Objective:** Teach students how Ansible works by manually configuring an EC2 instance

**Duration:** 45-60 minutes

**Difficulty:** Beginner-friendly

---

## 📋 Before Class: Preparation

### Prerequisites
- AWS account with EC2 access
- SSH key pair created locally: `~/.ssh/id_ed25519` (or your key)
- Ansible installed: `ansible --version`
- Terraform for infrastructure (optional first session)

### Pre-Demo Setup
1. Create EC2 instance manually in AWS Console (or use `make tf-apply`)
2. Get the public IP address
3. Test SSH access: `ssh -i ~/.ssh/id_ed25519 ubuntu@<IP>`

---

## 🚀 Class Flow (45 minutes)

### **Part 1: Explain Ansible (5 minutes)**

Show students the concept:
```
Your Computer          AWS EC2 Instance
     ↓                      ↑
   SSH ←─────────────────→ Ubuntu
     ↓                      ↑
  Ansible          (needs: IP + key + login)
```

**Key Teaching Points:**
- Ansible uses SSH (no agent needed)
- Need to tell Ansible: WHERE to connect, WHO to log in as, HOW to authenticate
- That's what an inventory file does!

---

### **Part 2: Show the Inventory File (5 minutes)**

#### Show the template:
```bash
cat inventory-example.ini
```

#### Output:
```ini
[ec2_instances]
# Replace these with your actual EC2 instance IPs or hostnames
ec2-instance-1 ansible_host=10.0.1.10 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/my-key.pem
```

#### Explain each part:
- `[ec2_instances]` = Group name (matches playbook's `hosts:`)
- `ansible_host=10.0.1.10` = **WHERE** (the IP address)
- `ansible_user=ec2-user` = **WHO** (login username)
- `ansible_ssh_private_key_file=~/.ssh/my-key.pem` = **HOW** (SSH key)

---

### **Part 3: Create Manual Inventory (10 minutes)**

#### Step 1: Get your EC2 instance details
```bash
# From AWS Console or Terraform output:
# Public IP: 52.123.45.67
# Key file: ~/.ssh/id_ed25519
# User: ubuntu (for Ubuntu AMI)
```

#### Step 2: Create inventory file
```bash
cat > ansible/inventory-manual.ini << 'EOF'
[ec2_instances]
# Your actual EC2 instance
demo-server ansible_host=52.123.45.67 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519

[ec2_instances:vars]
ansible_connection=ssh
ansible_port=22
EOF
```

#### Step 3: Verify connectivity (optional)
```bash
ansible all -i ansible/inventory-manual.ini -m ping
```

Expected output:
```
demo-server | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

---

### **Part 4: Show the Playbook (10 minutes)**

```bash
cat playbook-for-ec2-nginx.yml
```

#### Explain the structure:

```yaml
---
- name: Beginner Ansible Demo - EC2 Setup
  hosts: ec2_instances         # ← Matches [ec2_instances] group!
  become: true                 # ← Run as root (sudo)

  vars:                        # ← Variables
    app_name: "My EC2 Demo App"
    app_port: 80

  tasks:                       # ← What to do
    - name: Display EC2 instance information
      debug:
        msg: "..."

    - name: Install nginx
      package:
        name: nginx
        state: present

    # ... more tasks ...

  handlers:                    # ← Only run when notified
    - name: restart nginx
      service:
        name: nginx
        state: restarted
```

**Key Teaching Points:**
- `hosts: ec2_instances` connects to inventory group
- `tasks:` are executed in order
- `handlers:` only run when triggered
- Ansible modules are idempotent (safe to run multiple times)

---

### **Part 5: Run the Playbook LIVE (15 minutes)**

#### Command:
```bash
ansible-playbook -i ansible/inventory-manual.ini playbook-for-ec2-nginx.yml
```

#### What students will see:

```
PLAY [Beginner Ansible Demo - EC2 Setup] ****

TASK [Display EC2 instance information] **
ok: [demo-server] => {
    "msg": "Instance: 52.123.45.67\nOS: Ubuntu 24.04\nKernel: 5.15.0..."
}

TASK [Install nginx] **
changed: [demo-server]

TASK [Create application directory] **
changed: [demo-server]

TASK [Deploy HTML application] **
changed: [demo-server]

TASK [Configure nginx] **
changed: [demo-server]
changed: [demo-server] (via handler)

TASK [Enable nginx service] **
changed: [demo-server]

TASK [Verify nginx is responding] **
ok: [demo-server]

TASK [Display deployment success] **
ok: [demo-server] => {
    "msg": "✓ Deployment successful!\n\nAccess your app at:\nhttp://52.123.45.67:80"
}

PLAY RECAP **
demo-server : ok=8 changed=5 unreachable=0 failed=0
```

**Teaching Points:**
- `changed` = Ansible made a change
- `ok` = Already correct (idempotent!)
- Run it again: watch it show mostly `ok` (no changes needed)

---

### **Part 6: Test & Verify (5 minutes)**

```bash
# Test from terminal
curl http://52.123.45.67

# Or open in browser
# http://52.123.45.67
```

You'll see:
```html
<div class="container">
    <h1>🚀 My EC2 Demo App</h1>
    <p>Deployed successfully with Ansible!</p>
    
    <div class="info-box">
        <p><span class="label">Hostname:</span> <span class="value">ip-10-0-1-100</span></p>
        <p><span class="label">Distribution:</span> <span class="value">Ubuntu 24.04</span></p>
        <p><span class="label">Deployed at:</span> <span class="value">2026-11-21T14:32:15.123Z</span></p>
    </div>
</div>
```

---

## 🎯 Key Learning Outcomes

After this session, students will understand:

✅ **What Ansible is:**
- Configuration management tool
- Uses SSH for communication
- Runs on a control machine (your laptop)

✅ **Inventory files:**
- Define WHERE and HOW to connect
- Group hosts for organization
- Variables for each host

✅ **Playbooks:**
- YAML files describing desired state
- Run in order (sequential)
- Idempotent (safe to re-run)

✅ **Live deployment:**
- Saw Ansible install nginx in real-time
- Watched handlers (restart nginx)
- Verified service is running

---

## 💡 Discussion Points

### Why manual first?
- Students understand the basics
- They see what's happening
- Then Terraform automation makes sense!

### Next steps (Session 2):
- Show Terraform creating EC2 automatically
- Show auto-generated inventory
- Compare: manual vs automated
- Teach: "Infrastructure as Code"

---

## 🧹 Cleanup After Class

```bash
# Option 1: Keep running (for homework)
# No action needed - instance still running

# Option 2: Stop instance (save money, keep configuration)
aws ec2 stop-instances --instance-ids i-0123456789abcdef0 --region eu-west-2

# Option 3: Delete everything (complete cleanup)
aws ec2 terminate-instances --instance-ids i-0123456789abcdef0 --region eu-west-2
```

---

## 📚 Reference Commands

```bash
# Test connectivity
ansible all -i ansible/inventory-manual.ini -m ping

# Run playbook with verbose output
ansible-playbook -i ansible/inventory-manual.ini playbook-for-ec2-nginx.yml -v

# Run specific task only
ansible-playbook -i ansible/inventory-manual.ini playbook-for-ec2-nginx.yml --start-at-task="Install nginx"

# Dry run (show what would happen)
ansible-playbook -i ansible/inventory-manual.ini playbook-for-ec2-nginx.yml --check

# Run again (see idempotency)
ansible-playbook -i ansible/inventory-manual.ini playbook-for-ec2-nginx.yml
```

---

## ❓ Common Questions

**Q: Why use inventory files instead of just typing IP?**
A: Scale! With 100+ servers, you need organization. Inventory groups servers logically.

**Q: What if SSH fails?**
A: Check: IP is correct, key file path is right, instance is running, security group allows port 22.

**Q: Can I run playbooks without SSH keys?**
A: Yes - use passwords, but keys are more secure. SSH keys are best practice.

**Q: What's the difference between `tasks` and `handlers`?**
A: Tasks run always. Handlers run only when notified by a task. Great for restarting services when config changes.

---

## 🎓 Next Session Preview

After students understand the manual approach, show them:
1. **Terraform** creating EC2 automatically
2. **Terraform** generating inventory automatically  
3. **Ansible** using that generated inventory
4. **Full automation:** One command deploys everything

This progression: Manual → Automated → "Wow, this scales!"

---

## 📞 Support

If something breaks:
1. Check SSH: `ssh -i ~/.ssh/id_ed25519 ubuntu@<IP>`
2. Check inventory: `cat ansible/inventory-manual.ini`
3. Test connection: `ansible all -i ansible/inventory-manual.ini -m ping`
4. Run with verbose: `ansible-playbook -i ansible/inventory-manual.ini playbook-for-ec2-nginx.yml -vvv`

Good luck with your training! 🚀
