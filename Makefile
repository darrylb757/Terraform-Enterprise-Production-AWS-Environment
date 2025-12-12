# ---------------------------------
# Terraform Multi-Environment Makefile
# With Auto-Unlock + Color Output
# ---------------------------------

SHELL := /bin/bash

# Colors
GREEN  := \033[1;32m
YELLOW := \033[1;33m
RED    := \033[1;31m
BLUE   := \033[1;34m
NC     := \033[0m

# Paths
TF_DIR = envir/$(ENV)

# Detect Terraform Lock ID
get_lock_id = terraform state pull 2>/dev/null | grep -o '"ID":[^,]*' | awk -F '"' '{print $$4}'

# -----------------------------
# Generic Commands
# -----------------------------

init:
	@echo -e "$(BLUE)Initializing Terraform backend for $(ENV)...$(NC)"
	cd $(TF_DIR) && terraform init -reconfigure

plan:
	@echo -e "$(BLUE)Running Terraform PLAN for $(ENV)...$(NC)"
	@if cd $(TF_DIR) && terraform plan -var-file="$(ENV).tfvars"; then \
		echo -e "$(GREEN)Plan completed successfully.$(NC)"; \
	else \
		echo -e "$(RED)Plan failed — checking for stale lock...$(NC)"; \
		$(MAKE) unlock ENV=$(ENV); \
		exit 1; \
	fi

apply:
	@echo -e "$(BLUE)Running Terraform APPLY for $(ENV)...$(NC)"
	cd $(TF_DIR) && terraform apply -var-file="$(ENV).tfvars"

destroy:
	@echo -e "$(RED)Destroying Terraform resources for $(ENV)...$(NC)"
	cd $(TF_DIR) && terraform destroy -var-file="$(ENV).tfvars"

# -----------------------------
# AUTO-UNLOCK FUNCTION
# -----------------------------

unlock:
	@echo -e "$(YELLOW)Attempting auto-unlock for environment: $(ENV)...$(NC)"
	cd $(TF_DIR); \
	LOCK_ID=$(shell $(get_lock_id)); \
	if [ -z "$$LOCK_ID" ]; then \
		echo -e "$(GREEN)No lock detected. Nothing to unlock.$(NC)"; \
	else \
		echo -e "$(YELLOW)Found lock ID: $$LOCK_ID — unlocking...$(NC)"; \
		terraform force-unlock $$LOCK_ID --force || true; \
		echo -e "$(GREEN)Unlock process complete.$(NC)"; \
	fi

# -----------------------------
# Convenience Commands
# -----------------------------

dev:        ENV=dev
dev:        init apply

staging:    ENV=staging
staging:    init apply

production: ENV=production
production: init apply

plan-dev:        ENV=dev
plan-dev:        plan

plan-staging:    ENV=staging
plan-staging:    plan

plan-prod:       ENV=production
plan-prod:       plan

destroy-dev:         ENV=dev
destroy-dev:         destroy

destroy-staging:     ENV=staging
destroy-staging:     destroy

destroy-prod:        ENV=production
destroy-prod:        destroy

unlock-dev:         ENV=dev
unlock-dev:         unlock

unlock-staging:     ENV=staging
unlock-staging:     unlock

unlock-prod:        ENV=production
unlock-prod:        unlock

