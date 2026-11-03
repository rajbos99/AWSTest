output "roleA_arn" {
  value = aws_iam_role.roleA.arn
}

output "roleB_arn" {
  value = aws_iam_role.roleB.arn
}

output "roleC_arn" {
  value = aws_iam_role.roleC.arn
}

output "target_bucket_arn" {
  value = aws_s3_bucket.target_bucket.arn
}

output "ci_policy_arn" {
  value = aws_iam_policy.ci_least_privilege.arn
}
