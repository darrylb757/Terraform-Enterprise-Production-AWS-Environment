#!/bin/bash

set -e

BLUE="\e[34m"
YELLOW="\e[33m"
RESET="\e[0m"

ENV=$1

if [[ -z "$ENV" ]]; then
  echo -e "${YELLOW}Usage: ./init.sh dev|staging|production${RESET}"
  exit 1
fi

TF_DIR="envir/$ENV"

echo -e "${BLUE}Initializing Terraform backend for: $ENV${RESET}"

cd $TF_DIR
terraform init -upgrade
