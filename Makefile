.PHONY: help tf-fmt tf-init tf-validate tf-plan tf-apply tf-destroy \
	ansible-check local-test clean

TF_DIR := terraform
ANSIBLE_DIR := ansible
SSH_CIDR ?= $(shell curl -s https://checkip.amazonaws.com)/32

help:
	@echo "ec2-nginx-ansible Makefile targets:"
	@echo ""
	@echo "Terraform targets:"
	@echo "  make tf-fmt          Format Terraform files"
	@echo "  make tf-init         Initialize Terraform"
	@echo "  make tf-validate     Validate Terraform configuration"
	@echo "  make tf-plan         Plan Terraform deployment (shows changes)"
	@echo "  make tf-apply        Apply Terraform deployment (CAUTION: creates resources)"
	@echo "  make tf-destroy      Destroy Terraform resources (CAUTION: deletes resources)"
	@echo ""
	@echo "Ansible targets:"
	@echo "  make ansible-check   Check Ansible playbook syntax"
	@echo ""
	@echo "Combined targets:"
	@echo "  make local-test      Run all validation tests locally"
	@echo "  make clean           Remove Terraform state and lock files"
	@echo ""
	@echo "Usage:"
	@echo "  make tf-plan SSH_CIDR=YOUR_IP/32"
	@echo "  make local-test"

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

local-test: tf-fmt tf-validate ansible-check
	@echo ""
	@echo "======================================"
	@echo "✅ All local tests passed!"
	@echo "======================================"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Review the plan: make tf-plan SSH_CIDR=YOUR_IP/32"
	@echo "  2. Deploy: make tf-apply SSH_CIDR=YOUR_IP/32"
	@echo "  3. Configure: cd ansible && ansible-playbook playbook.yml"
	@echo "  4. Test: curl \$$(terraform -chdir=terraform output -raw url)"

clean:
	@echo "🧹 Cleaning Terraform files..."
	rm -rf $(TF_DIR)/.terraform
	rm -f $(TF_DIR)/.terraform.lock.hcl
	rm -f $(TF_DIR)/tfplan
	rm -f $(TF_DIR)/*.tfstate*
	rm -f $(ANSIBLE_DIR)/inventory.ini
	@echo "✅ Cleaned!"
