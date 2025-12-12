#!/bin/bash

set -e

# Colors
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

ENV=$1

if [[ -z "$ENV" ]]; then
  echo -e "${YELLOW}Usage: ./apply.sh dev|staging|production${RESET}"
  exit 1
fi

if [[ "$ENV" != "dev" && "$ENV" != "staging" && "$ENV" != "production" ]]; then
  echo -e "${RED}Error: Invalid environment '$ENV'${RESET}"
  exit 1
fi

if [[ "$ENV" == "production" ]]; then
  echo -e "${RED}WARNING: You are about to APPLY CHANGES to PRODUCTION.${RESET}"
  read -p "Type 'PROD' to continue: " confirm
  if [[ "$confirm" != "PROD" ]]; then
    echo -e "${RED}Aborted.${RESET}"
    exit 1
  fi
fi

TF_DIR="envir/$ENV"
TFVARS="$TF_DIR/$ENV.tfvars"

if [[ ! -f "$TFVARS" ]]; then
  echo -e "${RED}Missing tfvars file: $TFVARS${RESET}"
  exit 1
fi

echo -e "${BLUE}Running Terraform APPLY for environment: $ENV${RESET}"

cd $TF_DIR
terraform init -upgrade
terraform apply -var-file="$ENV.tfvars"

echo -e "${GREEN}Terraform APPLY completed for $ENV.${RESET}"

