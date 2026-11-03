# Target single named S3 bucket in Account B
resource "aws_s3_bucket" "target_bucket" {
  provider      = aws.account_b
  bucket        = var.target_s3_bucket_name
  force_destroy = false
}

# roleC: Assumable ONLY by roleB from Account A
data "aws_iam_policy_document" "roleC_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_a_id}:role/roleB"]
    }
  }
}

resource "aws_iam_role" "roleC" {
  provider           = aws.account_b
  name               = "roleC"
  assume_role_policy = data.aws_iam_policy_document.roleC_trust.json
}

# Full access scoped to the single named bucket and its contents
data "aws_iam_policy_document" "roleC_s3_permissions" {
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.target_bucket.arn,
      "${aws_s3_bucket.target_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "roleC_s3" {
  provider = aws.account_b
  name     = "roleC-s3-access"
  role     = aws_iam_role.roleC.id
  policy   = data.aws_iam_policy_document.roleC_s3_permissions.json
}
