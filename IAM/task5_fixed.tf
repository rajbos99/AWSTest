# Fixed version of the Task 5 snippet
# 1. Changed "arn:aws:iam::000000000000:user/roleB" to "arn:aws:iam::000000000000:role/roleB"
# 2. Replaced Resource = "*" with the specific target bucket and object ARNs

data "aws_iam_policy_document" "task5_roleC_trust_fixed" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::000000000000:role/roleB"]
    }
  }
}

resource "aws_iam_role" "task5_roleC_fixed" {
  provider           = aws.account_b
  name               = "roleC-fixed"
  assume_role_policy = data.aws_iam_policy_document.task5_roleC_trust_fixed.json
}

resource "aws_iam_role_policy" "task5_roleC_s3_fixed" {
  provider = aws.account_b
  name     = "roleC-s3-access-fixed"
  role     = aws_iam_role.task5_roleC_fixed.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::account-b-production-data-111111111111",
          "arn:aws:s3:::account-b-production-data-111111111111/*"
        ]
      }
    ]
  })
}
