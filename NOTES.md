# Notes

### Task 1: EC2 Provisioning

I set `prevent_destroy = true` on `prod-db`. The other instances (web, api, worker) are stateless and can easily be replaced or recreated if something happens to them, but the database holds actual state and persistent data on io2 storage. An accidental destroy or an in-place replacement (like an unexpected AMI update) would mean data loss and downtime.

Regarding the Terraform lifecycle block: Terraform evaluates `lifecycle` at compile time, so it doesn't allow dynamic values like `prevent_destroy = each.value.prevent_destroy`. To work around this while still driving all 5 instances from the single `var.instances` variable, I split them into two resource blocks (`protected` and `standard`) based on a boolean flag in the map, and merged their outputs at the end.

### Task 2: Remote State & Locking

If two engineers run `terraform apply` at the same time with local state, both will read the same state file initially. As they both run their changes against AWS, whichever apply finishes last will overwrite the state file with its own version, completely wiping out any record of the resources created by the first person. Those earlier resources become orphaned in AWS, which causes naming conflicts on future runs and usually requires manual imports or manual cleanup in the console. If things get interrupted mid-run, the state file can also end up corrupted.

Switching to S3 and DynamoDB fixes this:

- S3 keeps a single remote state file for everyone, with versioning enabled so we can restore previous versions if state gets messed up.
- DynamoDB handles state locking. Whenever someone runs a plan or apply, Terraform creates a lock entry in the DynamoDB table. If a second person tries to run apply concurrently, Terraform sees the lock and fails immediately with a message showing who holds it, preventing concurrent writes.

### Task 3: Cross-Account IAM

**1. Would I give engine and ci IAM users with access keys in production?**
No, definitely not. Long-lived access keys are one of the biggest security risks in AWS because they get leaked into git commits, build logs, or developer laptops, and they almost never get rotated properly.

In a real setup:

- For CI pipelines (GitHub Actions, GitLab, etc.), I'd use OIDC federation with an IAM role. The runner gets a short-lived token from the CI provider and assumes an AWS role via `sts:AssumeRoleWithWebIdentity`. No static keys needed at all.
- For the engine workload, I'd attach an IAM role directly to the compute resource. If it runs on EC2, use an instance profile. If it's on ECS, use an ECS task role. If on EKS, use IRSA or Pod Identity. For on-prem machines, AWS IAM Roles Anywhere is the way to go.

**2. Why trust roleB's ARN instead of the whole Account A root in roleC's trust policy?**
If Account B trusts Account A's root (`arn:aws:iam::000000000000:root`), it effectively hands over control to Account A's administrators. Any user, role, or admin in Account A with permission to assume roles could assume roleC.

By explicitly specifying `roleB`'s ARN (`arn:aws:iam::000000000000:role/roleB`), Account B ensures that only roleB can assume it, even if an admin in Account A tries to give someone else (like the ci user or an engineer) permission to assume roleC. This enforces the exact requirement that only roleB can access Account B's bucket.

### Task 4: CI Policy

The full policy JSON is saved in `IAM/task4_ci_policy.json` (and managed via `IAM/task4_ci_policy.tf`).

Here is what I deliberately left out of the policy and why:

- ECR deletion actions (`ecr:BatchDeleteImage`, `ecr:DeleteRepository`): The pipeline only builds and pushes new tags; it should never have rights to delete images or repositories. (Note: `ecr:GetAuthorizationToken` has to be `*` because AWS doesn't support resource-level permissions for auth tokens, but all actual push actions are locked to the specific repo).
- ECS cluster and service management (`ecs:CreateCluster`, `ecs:DeleteService`, etc.): The CI pipeline should only register new task definitions and update the existing service to deploy them. Destroying or creating clusters belongs in infrastructure code, not the deployment script.
- Broad `iam:PassRole`: I scoped `iam:PassRole` strictly to the execution role and task role needed by the service, with a condition that it can only be passed to `ecs.amazonaws.com`. Giving CI a wildcard `iam:PassRole` is a major privilege escalation risk because an attacker could use it to pass an admin role to a container.
- S3 write and delete actions: The prompt specified read-only access for build artifacts, so I only allowed `s3:GetObject` and `s3:ListBucket`. No `s3:PutObject` or delete actions, preventing the pipeline from overwriting or tampering with existing artifacts.

### Task 5: Bug Fix

The snippet had two issues:

1. In the trust policy, the principal identifier had `arn:aws:iam::000000000000:user/roleB`. But `roleB` is an IAM role, not a user. The ARN needs to be `:role/roleB`. Because of the `:user/` prefix, STS couldn't match the caller identity and was throwing an AccessDenied error when roleB tried to assume roleC.
2. In the permissions policy, it used `Action = "s3:*"` with `Resource = "*"`. That gave full administrative access to every single S3 bucket in the account. Task 3 specifically required access to a single named bucket, so the resource needed to be scoped down to the bucket ARN and its contents (`arn:aws:s3:::account-b-production-data-111111111111` and `arn:aws:s3:::account-b-production-data-111111111111/*`).
