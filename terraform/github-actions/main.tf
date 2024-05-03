terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket = "tfsate-5431fc87-88f1-495a-a440-b0ccdf187150"
    key    = "github_actions_experiments/github-actions.tfstate"
    region = "eu-central-1"
  }

  required_version = ">= 1.3.6"
}

provider "aws" {
  region = "eu-central-1"
}

data "aws_region" "current" {}

data "aws_iam_policy_document" "github_actions_experiments_github_actions" {
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
      values   = ["repo:Ring-r/github-actions-experiments:ref:refs/heads/<branch>"]
    }

    effect = "Allow"

    principals {
      identifiers = ["arn:aws:iam::592679440475:oidc-provider/token.actions.githubusercontent.com"]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "github_actions_experiments_github_actions" {
  name               = "GithubActionsExperimentsGithubActions-AssumeRoleWithAction"
  assume_role_policy = data.aws_iam_policy_document.github_actions_experiments_github_actions.json
}
