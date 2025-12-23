# /infra — Infrastructure as Code (Terraform)

This folder provisions AetherFlow infrastructure using Terraform.

Terraform is treated as the source of truth for cloud resources:
- Networking (VPC, subnets, routing)
- Storage (S3)
- Messaging (SQS + DLQs)
- Database (RDS Postgres)
- Compute (ECS Fargate)
- Exposure (ALB)
- IAM roles and policies
- Logging (CloudWatch)

Principles:
- No secrets in Terraform state
- Minimal public surface area: only ALB is public
- Private networking for DB and internal services
- Strong IAM least-privilege for task roles
