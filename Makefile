.PHONY: help tf-fmt tf-init tf-validate tf-plan tf-apply tf-destroy \
	ansible-check ansible-run local-test clean demo-setup demo-status demo-info demo-destroy

TF_DIR := terraform
ANSIBLE_DIR := ansible
SSH_CIDR ?= $(shell curl -s https://checkip.amazonaws.com)/32

help:
	@echo "╔════════════════════════════════════════════════════════════════╗"
	@echo "║   nginx on EC2 — Terraform + Ansible Demo                     ║"
	@echo "║   Perfect for learning Infrastructure as Code & Configuration ║"
	@echo "╚════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "📋 QUICK START:"
	@echo "  make demo-setup      Create EC2 + install nginx (full demo)"
	@echo "  make demo-status     Show deployment details"
	@echo "  make demo-destroy    Tear down everything"
	@echo ""
	@echo "🏗️  TERRAFORM (Infrastructure)"
	@echo "  make tf-init         Download AWS provider plugins"
	@echo "  make tf-validate     Check syntax of Terraform files"
	@echo "  make tf-plan         Show what will be created (no changes yet)"
	@echo "  make tf-apply        Create the EC2 instance on AWS"
	@echo "  make tf-destroy      Delete the EC2 instance (WARNING!)"
	@echo ""
	@echo "⚙️  ANSIBLE (Configuration)"
	@echo "  make ansible-check   Validate Ansible playbook syntax"
	@echo "  make ansible-run     Run the playbook (install nginx)"
	@echo ""
	@echo "✅ TESTING & VALIDATION"
	@echo "  make local-test      Validate all code locally (no AWS)"
	@echo "  make demo-info       Show current deployment info"
	@echo ""
	@echo "🧹 CLEANUP"
	@echo "  make clean           Remove state files & temporary files"
	@echo ""
	@echo "📌 CUSTOM SSH CIDR:"
	@echo "  make tf-plan SSH_CIDR=203.0.113.0/32"

demo-setup: tf-apply ansible-run demo-info
	@echo ""
	@echo "✨ Demo is ready!"
	@echo ""
	@echo "Your nginx instance is running. Access it here:"
	@echo "  🌐 http://$$(terraform -chdir=$(TF_DIR) output -raw public_ip)"
	@echo ""
	@echo "Or via DNS:"
	@echo "  🌐 $$(terraform -chdir=$(TF_DIR) output -raw url)"

demo-status:
	@echo "📊 Current Deployment Status:"
	@echo ""
	@if [ -f $(TF_DIR)/terraform.tfstate ]; then \
		echo "✅ Instance deployed"; \
		terraform -chdir=$(TF_DIR) output; \
	else \
		echo "❌ No instance deployed (run 'make demo-setup')"; \
	fi

demo-info:
	@echo "📋 Deployment Information:"
	@echo ""
	@if [ -f $(TF_DIR)/terraform.tfstate ]; then \
		echo "Instance ID: $$(terraform -chdir=$(TF_DIR) output -raw instance_id)"; \
		echo "Public IP:   $$(terraform -chdir=$(TF_DIR) output -raw public_ip)"; \
		echo "Private IP:  $$(terraform -chdir=$(TF_DIR) output -raw private_ip)"; \
		echo "Region:      $$(terraform -chdir=$(TF_DIR) output -raw vpc_id | head -c 10)..."; \
		echo ""; \
		echo "Access nginx at:"; \
		echo "  curl $$(terraform -chdir=$(TF_DIR) output -raw url)"; \
		echo "  ssh ubuntu@$$(terraform -chdir=$(TF_DIR) output -raw public_ip)"; \
	else \
		echo "No instance found. Run 'make demo-setup' first."; \
	fi

demo-destroy: clean
	@echo "⚠️  WARNING: This will DESTROY AWS resources!"
	@echo ""
	@read -p "Are you absolutely sure? Type 'destroy-demo' to confirm: " confirm; \
	if [ "$$confirm" = "destroy-demo" ]; then \
		terraform -chdir=$(TF_DIR) destroy -var="ssh_cidr=0.0.0.0/32"; \
		echo "✅ Destroyed!"; \
	else \
		echo "❌ Cancelled"; \
	fi

tf-fmt:
	@echo "🔍 Formatting Terraform files..."
	terraform -chdir=$(TF_DIR) fmt -recursive

tf-init:
	@echo "📦 Initializing Terraform..."
	terraform -chdir=$(TF_DIR) init

tf-validate: tf-init
	@echo "✅ Validating Terraform configuration..."
	terraform -chdir=$(TF_DIR) validate

tf-plan: tf-validate
	@echo "📋 Planning Terraform deployment..."
	@echo "SSH CIDR: $(SSH_CIDR)"
	terraform -chdir=$(TF_DIR) plan -var="ssh_cidr=$(SSH_CIDR)" -lock=false

tf-apply: tf-validate
	@echo "⚠️  WARNING: This will CREATE AWS resources!"
	@echo "SSH CIDR: $(SSH_CIDR)"
	@echo ""
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		terraform -chdir=$(TF_DIR) apply -var="ssh_cidr=$(SSH_CIDR)"; \
	else \
		echo "❌ Cancelled"; \
	fi

tf-destroy:
	@echo "⚠️  WARNING: This will DESTROY AWS resources!"
	@echo ""
	@read -p "Are you sure? Type 'destroy' to confirm: " confirm; \
	if [ "$$confirm" = "destroy" ]; then \
		terraform -chdir=$(TF_DIR) destroy -var="ssh_cidr=0.0.0.0/32"; \
	else \
		echo "❌ Cancelled"; \
	fi

ansible-check:
	@echo "🔍 Checking Ansible playbook syntax..."
	cd $(ANSIBLE_DIR) && ansible-playbook --syntax-check -i "localhost," playbook.yml

ansible-run:
	@echo "⚙️  Running Ansible playbook to configure nginx..."
	@if [ ! -f $(ANSIBLE_DIR)/inventory.ini ]; then \
		echo "❌ Error: inventory.ini not found!"; \
		echo "Run 'make tf-apply' first to create the EC2 instance."; \
		exit 1; \
	fi
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini playbook.yml
	@echo ""
	@echo "✅ nginx is now installed and running!"

local-test: tf-fmt tf-validate ansible-check
	@echo ""
	@echo "╔════════════════════════════════════════════╗"
	@echo "║   ✅ All local tests PASSED!              ║"
	@echo "║   Code is ready for deployment             ║"
	@echo "╚════════════════════════════════════════════╝"
	@echo ""
	@echo "📋 Next steps:"
	@echo "  1️⃣  Review changes:  make tf-plan SSH_CIDR=YOUR_IP/32"
	@echo "  2️⃣  Deploy:          make tf-apply SSH_CIDR=YOUR_IP/32"
	@echo "  3️⃣  Or full setup:   make demo-setup"
	@echo ""
	@echo "💡 Pro tip: Run 'make help' to see all available commands"

clean:
	@echo "🧹 Cleaning Terraform files..."
	rm -rf $(TF_DIR)/.terraform
	rm -f $(TF_DIR)/.terraform.lock.hcl
	rm -f $(TF_DIR)/tfplan
	rm -f $(TF_DIR)/*.tfstate*
	rm -f $(ANSIBLE_DIR)/inventory.ini
	@echo "✅ Cleaned!"
