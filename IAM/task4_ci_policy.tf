# Custom scoped IAM policy for the ci user
data "aws_iam_policy_document" "ci_least_privilege" {
  # 1. ECR login token (AWS requires * on GetAuthorizationToken)
  statement {
    sid       = "ECRAuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # 2. Push Docker images to specific ECR repository
  statement {
    sid    = "ECRPushRepo"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    resources = [
      "arn:aws:ecr:${var.aws_region}:${var.account_a_id}:repository/${var.ci_ecr_repo_name}"
    ]
  }

  # 3. Register and inspect new task definitions
  statement {
    sid    = "ECSTaskDef"
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition"
    ]
    resources = ["*"]
  }

  # 4. Deploy new task definition to specific ECS service
  statement {
    sid    = "ECSUpdateService"
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices"
    ]
    resources = [
      "arn:aws:ecs:${var.aws_region}:${var.account_a_id}:service/${var.ci_ecs_cluster_name}/${var.ci_ecs_service_name}"
    ]
  }

  # 5. iam:PassRole scoped to ECS task execution and task roles only
  statement {
    sid    = "PassRoleToECS"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${var.account_a_id}:role/ecsTaskExecutionRole",
      "arn:aws:iam::${var.account_a_id}:role/ecsAppTaskRole"
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs.amazonaws.com"]
    }
  }

  # 6. Read-only access to build artifacts S3 bucket
  statement {
    sid    = "S3ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.ci_build_artifacts_bucket}"
    ]
  }

  statement {
    sid    = "S3GetObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "arn:aws:s3:::${var.ci_build_artifacts_bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "ci_least_privilege" {
  provider    = aws.account_a
  name        = "ci-deployment-policy"
  description = "Scoped policy for CI pipeline builds and ECS deployments"
  policy      = data.aws_iam_policy_document.ci_least_privilege.json
}

resource "aws_iam_user_policy_attachment" "ci_least_privilege_attach" {
  provider   = aws.account_a
  user       = aws_iam_user.ci.name
  policy_arn = aws_iam_policy.ci_least_privilege.arn
}
