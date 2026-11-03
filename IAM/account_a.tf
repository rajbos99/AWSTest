# Group 1: CLI / programmatic-only access (no console login profile created)
resource "aws_iam_group" "group1" {
  provider = aws.account_a
  name     = "group1"
}

resource "aws_iam_user" "engine" {
  provider      = aws.account_a
  name          = "engine"
  force_destroy = true
}

resource "aws_iam_user" "ci" {
  provider      = aws.account_a
  name          = "ci"
  force_destroy = true
}

resource "aws_iam_group_membership" "group1_membership" {
  provider = aws.account_a
  name     = "group1-members"
  group    = aws_iam_group.group1.name
  users = [
    aws_iam_user.engine.name,
    aws_iam_user.ci.name
  ]
}

# Group 2: Full console + CLI access
resource "aws_iam_group" "group2" {
  provider = aws.account_a
  name     = "group2"
}

resource "aws_iam_user" "alice" {
  provider      = aws.account_a
  name          = "alice"
  force_destroy = true
}

resource "aws_iam_user" "bob" {
  provider      = aws.account_a
  name          = "bob"
  force_destroy = true
}

resource "aws_iam_group_membership" "group2_membership" {
  provider = aws.account_a
  name     = "group2-members"
  group    = aws_iam_group.group2.name
  users = [
    aws_iam_user.alice.name,
    aws_iam_user.bob.name
  ]
}

# roleA: Administrative access to all AWS services except IAM
data "aws_iam_policy_document" "roleA_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_a_id}:root"]
    }
  }
}

resource "aws_iam_role" "roleA" {
  provider           = aws.account_a
  name               = "roleA"
  assume_role_policy = data.aws_iam_policy_document.roleA_trust.json
}

data "aws_iam_policy_document" "roleA_permissions" {
  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }

  statement {
    effect = "Deny"
    actions = [
      "iam:*",
      "organizations:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "roleA_policy" {
  provider = aws.account_a
  name     = "roleA-admin-except-iam"
  role     = aws_iam_role.roleA.id
  policy   = data.aws_iam_policy_document.roleA_permissions.json
}

# roleB: Only permission is assuming roleC in Account B
data "aws_iam_policy_document" "roleB_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_a_id}:root"]
    }
  }
}

resource "aws_iam_role" "roleB" {
  provider           = aws.account_a
  name               = "roleB"
  assume_role_policy = data.aws_iam_policy_document.roleB_trust.json
}

data "aws_iam_policy_document" "roleB_permissions" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${var.account_b_id}:role/roleC"]
  }
}

resource "aws_iam_role_policy" "roleB_policy" {
  provider = aws.account_a
  name     = "roleB-assume-roleC-only"
  role     = aws_iam_role.roleB.id
  policy   = data.aws_iam_policy_document.roleB_permissions.json
}
