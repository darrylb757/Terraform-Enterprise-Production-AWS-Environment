#!/bin/bash

set -e

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

ENV=$1

if [[ -z "$ENV" ]]; then
  echo -e "${YELLOW}Usage: ./destroy.sh dev|staging|production${RESET}"
  exit 1
fi

if [[ "$ENV" == "production" ]]; then
  echo -e "${RED}⚠️  DANGER: You are attempting to DESTROY PRODUCTION.${RESET}"
  read -p "Type 'DESTROY-PROD' to continue: " confirm
  if [[ "$confirm" != "DESTROY-PROD" ]]; then
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

echo -e "${YELLOW}Destroying Terraform resources for: $ENV${RESET}"

cd $TF_DIR
terraform destroy -var-file="$ENV.tfvars"

echo -e "${GREEN}Destroy complete for $ENV.${RESET}"

