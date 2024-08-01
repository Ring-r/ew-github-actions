# change locals, terraform.backend.s3.bucket, terraform.backend.s3.key.

locals {
  repository_owner                = "Ring-r"
  repository_name                 = "ew-github-actions"
  repository_branch               = "main"
  aws_iam_openid_connect_provider = "arn:aws:iam::592679440475:oidc-provider/token.actions.githubusercontent.com" # use `aws iam list-open-id-connect-providers | grep -om1 'arn:aws:iam::[0123456789]*:oidc-provider/token.actions.githubusercontent.com'` to get correct data if it exists.
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket = "tfsate-5431fc87-88f1-495a-a440-b0ccdf187150" # use `aws s3 ls | grep -om1 'tfstate-.*'` to get correct data if it exists.
    key    = "github_actions_experiments/github-actions.tfstate"
    region = "eu-central-1"
  }

  required_version = ">= 1.3.6"
}

provider "aws" {
  region = "eu-central-1"
}

data "aws_region" "current" {}

data "aws_iam_policy_document" "github_actions" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.repository_owner}/${local.repository_name}:ref:refs/heads/${local.repository_branch}"]
    }

    effect = "Allow"

    principals {
      identifiers = [local.aws_iam_openid_connect_provider]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${local.repository_name}-GithubActions-AssumeRoleWithAction"
  assume_role_policy = data.aws_iam_policy_document.github_actions.json
}
