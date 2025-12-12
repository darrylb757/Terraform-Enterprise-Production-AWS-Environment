#!/bin/bash

set -e

BLUE="\e[34m"
GREEN="\e[32m"
RESET="\e[0m"

ENV=$1

if [[ -z "$ENV" ]]; then
  echo -e "Usage: ./validate.sh dev|staging|production"
  exit 1
fi

TF_DIR="envir/$ENV"

cd $TF_DIR

echo -e "${BLUE}Running terraform fmt...${RESET}"
terraform fmt -recursive

echo -e "${BLUE}Running terraform validate...${RESET}"
terraform validate

echo -e "${GREEN}Validation complete for $ENV.${RESET}"
