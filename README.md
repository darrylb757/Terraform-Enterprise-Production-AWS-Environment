🌐 Production-Style AWS Environment with Terraform

This repository contains a fully modular, multi-environment Infrastructure-as-Code (IaC) setup built using Terraform. The architecture mirrors real-world enterprise cloud environments, emphasizing:

🔐 Security

🔄 Scalability

🧩 Modular design

🚀 Automation

🧭 Environment isolation

📊 Monitoring & alerting

💰 Cost governance

This project demonstrates production-level thinking as a Cloud Engineer / DevOps Engineer, showcasing skills that employers expect in modern cloud infrastructure automation.

🏗️ High-Level Architecture
![Architecture Diagram](images/757aws_enterprise_architecture.png)

📁 Repository Structure

Here is your complete project layout with explanations for every folder and file.

![Architecture Diagram](images/structure2.png)



🗂️ /envir — Environment-Specific Terraform Configurations

This folder manages environment isolation, a best practice in enterprise cloud deployments.

Each environment (dev, staging, production) contains its own Terraform root module — allowing you to safely deploy independent versions of the same architecture.

🔑 /envir/bootstrap — Terraform Backend Setup

Used only once to create:

📦 S3 remote backend for storing Terraform state

🔒 DynamoDB table for state locking

Files include:

File	Purpose
main.tf	Creates backend infrastructure
variables.tf	Input variables such as bucket/table names
outputs.tf	Shows the created backend resources
terraform.tfstate*	Local state files from initial bootstrap

Why this matters:
✔️ Prevents state corruption
✔️ Enables team collaboration
✔️ Enables environment locking and drift detection

🧪 /envir/dev (and staging, production)

These folders define the root modules that call the reusable modules under /modules.

Files inside each environment:
File	Purpose
versions.tf	Terraform + provider version constraints
provider.tf	AWS provider + backend configuration
variables.tf	Declares variables used by the root module
main.tf	Calls modules: VPC, ALB, ASG, S3, IAM, Monitoring
<env>.tfvars	💡 Actual environment values (names, CIDRs, etc.)
outputs.tf	Returns VPC IDs, ALB DNS names, bucket names, etc.

Why this structure is enterprise-grade:
✔️ Protects production from accidental changes
✔️ Allows CI/CD pipelines to deploy to specific environments
✔️ Enforces consistency across cloud environments

🧩 /modules — Reusable Terraform Modules

Your modules follow Terraform best practices, enabling:

Maintainability

Reusability

Rapid scaling

Environment-agnostic architecture

🌐 modules/vpc

Handles all networking:

VPC

Public & private subnets

Internet Gateway

NAT Gateway

Route tables

VPC Flow Logs → S3

Why enterprises use this:
✔️ Network segmentation
✔️ Private compute security
✔️ Logging for audits
✔️ Multi-AZ resiliency

⚖️ modules/alb

Creates the Application Load Balancer:

ALB resource

Listener

Security group

Target group

Why this is important:
✔️ Highly available entry point
✔️ Controlled inbound traffic
✔️ Health checking
✔️ Zero-downtime deployments

🖥️ modules/compute-asg

Creates scalable compute resources:

EC2 Launch Template

Auto Scaling Group

EC2 instance IAM role

Security group

Benefits:
✔️ Self-healing servers
✔️ Automatic horizontal scaling
✔️ Controlled outbound/inbound access
✔️ Production-grade availability

📦 modules/s3

Configures an application S3 bucket:

AES-256 encryption

Versioning

TLS-only access policy

Public access blocked

Lifecycle policies

Why this matters:
✔️ Compliance (HIPAA, SOC2, ISO)
✔️ Secure object storage
✔️ Controlled data retention

🔐 modules/iam

Defines IAM roles and permissions:

EC2 IAM role + instance profile

Lambda execution role

Policy attachments

Why this is critical:
✔️ Principle of least privilege
✔️ Secure role separation
✔️ Service-to-service permissions

📊 modules/monitoring

Enterprise observability module:

CloudWatch Alarms

SNS Topics

Email subscriptions

Lambda → Slack notifications

AWS Budgets alerts

Why this is awesome:
✔️ Real-time alerting
✔️ Cost governance
✔️ Error visibility
✔️ Automated notifications

Inside this module:

/lambda/slack_lambda.py

Python Lambda function that formats and sends Slack alerts.

🤖 /scripts — Automation Helpers
scripts/
├─ init.sh
├─ validate.sh
├─ apply.sh
└─ destroy.sh


Used to standardize Terraform operations.

Why this matters:
✔️ Reduces human error
✔️ Makes deployments consistent
✔️ Mirrors CI/CD pipelines

🛠️ Makefile — Enterprise Deployment Automation

Examples:

make init ENV=dev
make plan ENV=dev
make apply ENV=dev
make destroy ENV=dev


✔️ Shows process automation skills
✔️ Demonstrates structured workflows
✔️ Enables reproducible operations

🚀 Why This Project Is Production-Ready
Feature	Value
🔐 IAM roles	Least-privilege access
🌐 Multi-AZ VPC	High availability
🧱 Private subnets	Secure compute layer
⚖️ ALB + ASG	Autoscaling & resilience
📦 Encrypted S3	Compliance & data protection
📊 Monitoring stack	Real-time alerting
💰 Budgets alerts	Cost control
⛓️ Remote backend	Safe Terraform collaboration
This project reflects how real companies build infrastructure. 

