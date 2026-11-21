# EC2 Ansible Demo Guide

This guide walks you through using the **ec2-start-demo.yml** playbook to deploy a demo application to AWS EC2 instances.

## Prerequisites

1. **Ansible installed** on your local machine
   ```bash
   pip install ansible boto3 botocore
   ```

2. **AWS EC2 instances running** (Amazon Linux 2 or similar)
   - Security group allows SSH (port 22)
   - Security group allows HTTP (port 80)

3. **SSH key pair** to connect to EC2 instances
   - Download from AWS Console: `.pem` file
   - Set permissions: `chmod 600 ~/.ssh/my-key.pem`

## Step 1: Create Inventory File

Create `inventory.ini` with your EC2 instance details:

```ini
[ec2_instances]
web-server-1 ansible_host=ec2-X-X-X-X.eu-west-1.compute.amazonaws.com ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/my-key.pem

[ec2_instances:vars]
ansible_connection=ssh
ansible_port=22
```

**Where to find this info:**
- `ansible_host`: Public IP or hostname from AWS Console
- `ansible_user`: `ec2-user` for Amazon Linux, `admin` for Debian/Ubuntu
- SSH key file: Path to your `.pem` file

## Step 2: Test SSH Connection

```bash
ansible -i inventory.ini ec2_instances -m ping
```

Expected output:
```
web-server-1 | SUCCESS => {
    "ping": "pong"
}
```

## Step 3: Run the Playbook

```bash
ansible-playbook -i inventory.ini ec2-start-demo.yml
```

This will:
- Gather facts about the instances
- Update all system packages
- Install nginx
- Deploy a demo HTML application
- Start nginx service
- Verify it's working

## Step 4: Access Your Application

After the playbook completes, visit:

```
http://<your-ec2-public-ip>
```

You should see the demo page with instance information.

## Customization

### Change the app name:

```bash
ansible-playbook -i inventory.ini ec2-start-demo.yml -e app_name="My Custom App"
```

### Change the port:

```bash
ansible-playbook -i inventory.ini ec2-start-demo.yml -e app_port=8080
```

### Run on specific host:

```bash
ansible-playbook -i inventory.ini ec2-start-demo.yml -l web-server-1
```

## Troubleshooting

### SSH connection refused

- Check security group allows SSH (port 22)
- Verify SSH key file path is correct
- Test: `ssh -i ~/.ssh/my-key.pem ec2-user@<public-ip>`

### Permission denied (become)

- The playbook uses `become: true` for sudo
- Some systems may require password. Add `--ask-become-pass` or configure passwordless sudo

### Nginx not starting

- Check EC2 instance has enough resources (CPU, memory)
- Verify security group allows HTTP (port 80)
- SSH to instance and run: `sudo systemctl status nginx`

## Learning Points for Beginners

**Key Ansible concepts demonstrated:**

1. **Inventory** - How to define target hosts
2. **Variables** - Using `{{ }}` for dynamic values
3. **Handlers** - Running tasks only when changes occur
4. **Conditionals** - `when:` statements for OS-specific tasks
5. **Templating** - Generating nginx config dynamically
6. **Modules** - Different Ansible modules (package, file, service, uri, etc.)
7. **Post-tasks** - Running tasks after main playbook completes
8. **Debugging** - Using `debug` module to output information

## Next Steps

- Modify the HTML template for your own branding
- Add more tasks (install packages, configure firewalls, etc.)
- Use dynamic inventory with AWS auto-discovery
- Add rollback playbooks for cleanup

---

**Happy automating! 🚀**
