terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Terraform tự lấy thumbprint từ GitHub
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ── 1. Lấy thông tin AWS account hiện tại ──────────────────
data "aws_caller_identity" "current" {}

# ── 2. Tạo OIDC Provider ───────────────────────────────────
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # Thumbprint của GitHub OIDC
  # Tự động lấy thumbprint — không cần hardcode
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name      = "github-actions-oidc"
    ManagedBy = "terraform"
  }
}

# ── 3. Trust Policy — chỉ cho phép repo của bạn ───────────
data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # Giới hạn chỉ repo cụ thể
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

# ── 4. Tạo IAM Role ────────────────────────────────────────
resource "aws_iam_role" "github_actions" {
  name               = "github-actions-terraform-role"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json

  tags = {
    Name      = "github-actions-terraform-role"
    ManagedBy = "terraform"
  }
}

# ── 5. Permission cho Role ─────────────────────────────────
data "aws_iam_policy_document" "terraform_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
      "ec2:*",
      "iam:GetRole",
      "iam:PassRole",
      "iam:ListRoles"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "terraform_policy" {
  name        = "github-actions-terraform-policy"
  description = "Permission cho Terraform chạy qua GitHub Actions"
  policy      = data.aws_iam_policy_document.terraform_permissions.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.terraform_policy.arn
}