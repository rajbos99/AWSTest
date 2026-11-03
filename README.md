# Terraform AWS Assignment

Terraform code and notes for the assignment tasks.

## Layout

- EC2/ - Task 1 (EC2 provisioning module) and Task 2 (S3/DynamoDB remote state config)
- IAM/ - Task 3 (cross-account IAM setup), Task 4 (least-privilege CI policy), Task 5 (bug fix)
- NOTES.md - Written answers and explanations for each task

## Validation

Run terraform validate to check both modules:

```bash
cd EC2
terraform init -backend=false
terraform validate

cd ../IAM
terraform init
terraform validate
```
