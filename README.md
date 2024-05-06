# github-actions-experiments

experiments with github actions

## steps to reproduce.

[Understanding GitHub Actions - GitHub Docs](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions).

### create base environment.

create repository.
run steps from [Quickstart for repositories - GitHub Docs](https://docs.github.com/en/repositories/creating-and-managing-repositories/quickstart-for-repositories).

default configuration changes:
- repository name: github-actions-experiments;
- description: experiments with github actions;
- add a readme file;

### create base workflow.

```shell
mkdir -p .github/workflows
vim .github/workflows/blank.yml
```

```yaml
# This is a basic workflow to help you get started with Actions

name: blank

# Controls when the workflow will run
on:
  # Triggers the workflow on push or pull request events but only for the "main" branch
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

# A workflow run is made up of one or more jobs that can run sequentially or in parallel
jobs:
  # This workflow contains a single job called "build"
  build:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest

    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
      # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
      - uses: actions/checkout@v4

      # Runs a single command using the runners shell
      - name: Run a one-line script
        run: echo Hello, world!

      # Runs a set of commands using the runners shell
      - name: Run a multi-line script
        run: |
          echo Add other actions to build,
          echo test, and deploy your project.
```

there are some warnings without using last version of actions.
update version of used actions.
last version can be find in [GitHub - actions/checkout: Action for checking out a repo](https://github.com/actions/checkout).

commit and push changes to run workflow.

### create aws workflow.

#### create necessary role.

 [Use IAM roles to connect GitHub Actions to actions in AWS | AWS Security Blog](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/).
 [Configuring OpenID Connect in Amazon Web Services - GitHub Enterprise Cloud Docs](https://docs.github.com/en/enterprise-cloud@latest/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
 [Create a role for OpenID Connect federation (console) - AWS Identity and Access Management](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html#idp_oidc_Create_GitHub).
 [Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)

there is using terraform to create necessary role.

alternative. aws cli is used to create necessary policy and role (see links above).

```shell
mkdir -p terraform/github-actions
vim terraform/github-actions/main.tf
```

```terraform
# change locals, terraform.backend.s3.bucket, terraform.backend.s3.key.

locals {
  repository_owner                = <repository_owner>
  repository_name                 = <repository_name>
  repository_branch               = <repository_branch>
  aws_iam_openid_connect_provider = <aws_iam_openid_connect_provider>  # use `aws iam list-open-id-connect-providers | grep -om1 'arn:aws:iam::[0123456789]*:oidc-provider/token.actions.githubusercontent.com'` to get correct data if it exists.
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket = <terraform.backend.s3.bucket>  # use `aws s3 ls | grep -om1 'tfstate-.*'` to get correct data if it exists.
    key    = <terraform.backend.s3.key>  # replace <repository_name> in "<repository_name>/github-actions.tfstate" and use.
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
  assume_role_policy = "data.aws_iam_policy_document.github_actions.json"
}
```

change necesary data:
- <repository_owner> -> "Ring-r";
- <repository_name> -> "github-actions-experiments";
- <repository_branch> -> "main";
- <aws_iam_openid_connect_provider>:
use follow to get correct data:
```shell
aws iam list-open-id-connect-providers | grep -om1 'arn:aws:iam::[0123456789]*:oidc-provider/token.actions.githubusercontent.com'
```
use follow to create correct data if it doesn't exist (should be created once for all projects (the same owner) which use github actions and aws):
```shell
aws iam create-open-id-connect-provider --url "https://token.actions.githubusercontent.com" --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" --client-id-list "sts.amazonaws.com"
```
- <terraform.backend.s3.bucket>:
use follow to get correct data:
```shell
aws s3 ls | grep -om1 'tfstate-.*'
```
use follow to create correct data if it doesn't exist (should be created once for all owner projects (the same owner) which use terrafor s3 backend):
TODO: describe how create correect bucket if it doesn't exist.
- <terraform.backend.s3.key> -> "<repository_name>/github-actions.tfstate" -> "github-actions-experiments/github-actions.tfstate".

apply terraform configuration
```shell
cd terraform/github-actions
terraform fmt
terraform validate
terraform init
terraform plan
terraform apply
cd ../..
```

#### use credentials in aws workflow.

[GitHub - aws-actions/configure-aws-credentials: Configure AWS credential environment variables for use in other GitHub Actions.](https://github.com/aws-actions/configure-aws-credentials).

there is using identity provider to connect aws and github.

alternative. [Terraform with GitHub Actions : How to Manage & Scale](https://spacelift.io/blog/github-actions-terraform).
Create an IAM user access key by using AWS Console and store it in GitHub Actions secrets named `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

```shell
mkdir -p .github/workflows
vim .github/workflows/aws.yml
```

```yaml
# This workflow use AWS CLI.
# role_to_assume: `aws iam get-role --role-name "<repository_name>-GitHubActions-AssumeRoleWithAction"`

name: aws

# Controls when the workflow will run
on:
  # Triggers the workflow on push or pull request events but only for the "main" branch
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

env:
  AWS_REGION : "eu-central-1"

permissions:
  id-token: write # This is required for requesting the JWT
  contents: read  # This is required for actions/checkout

# A workflow run is made up of one or more jobs that can run sequentially or in parallel
jobs:
  # This workflow contains a single job called "build"
  build:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest

    # Use the Bash shell regardless whether the GitHub Actions runner is ubuntu-latest, macos-latest, or windows-latest
    defaults:
      run:
        shell: bash

    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
      # ...

      - name: configure aws credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: ${{ env.AWS_REGION }}
          disable-retry: true
          role-to-assume: <role_to_assume>

      # ...
```

there are some warnings without using last version of actions.
update version of used actions.
last version of configure-aws-credentials can be find in [GitHub - aws-actions/configure-aws-credentials: Configure AWS credential environment variables for use in other GitHub Actions.](https://github.com/aws-actions/configure-aws-credentials).

change necesary data:
- <role_to_assume>:
use follow to get correct data:
```shell
aws iam get-role --role-name "github-actions-experiments-GitHubActions-AssumeRoleWithAction"
```

commit and push changes to run workflow.

### create terraform workflow.
using aws and terraform workflows from github.com (look "Deploy to Amazon ECS" and "Terraform" in actions/new).

```shell
vim main.tf
```

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

# An example resource that does nothing.
resource "null_resource" "example" {
  triggers = {
    value = "A example resource that does nothing!"
  }
}
```

```shell
vim .github/workflows/terraform.yml
```

```yaml
# This workflow installs the latest Terraform CLI and configures them.
# On pull request events, this workflow will run `terraform init`, `terraform fmt`, and `terraform plan`.
# On push events to the "main" branch, `terraform apply` will be executed.
#
# Documentation for `hashicorp/setup-terraform` is located here: https://github.com/hashicorp/setup-terraform

name: 'Terraform'

on:
  push:
    branches: [ "main" ]
  pull_request:

permissions:
  contents: read

jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest

    # Use the Bash shell regardless whether the GitHub Actions runner is ubuntu-latest, macos-latest, or windows-latest
    defaults:
      run:
        shell: bash

    steps:
    # ...

    # Install the latest version of Terraform CLI and configure the Terraform CLI configuration file with a Terraform Cloud user API token
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3

    # Initialize a new or existing Terraform working directory by creating initial files, loading any remote state, downloading modules, etc.
    - name: Terraform Init
      run: terraform init

    # Checks that all Terraform configuration files adhere to a canonical format
    - name: Terraform Format
      run: terraform fmt -check

    # Generates an execution plan for Terraform
    - name: Terraform Plan
      run: terraform plan -input=false

      # On push to "main", build or change infrastructure according to Terraform configuration files
      # Note: It is recommended to set up a required "strict" status check in your repository for "Terraform Cloud". See the documentation on "strict" required status checks for more information: https://help.github.com/en/github/administering-a-repository/types-of-required-status-checks
    - name: Terraform Apply
      if: github.ref == 'refs/heads/"main"' && github.event_name == 'push'
      run: terraform apply -auto-approve -input=false
```

commit and push changes to run workflow.

### create action to update aws lambda.

#### TODO: make research.
- [AWS Lambda Deploy · Actions · GitHub Marketplace · GitHub](https://github.com/marketplace/actions/aws-lambda-deploy);
- [Using GitHub Actions to deploy serverless applications | AWS Compute Blog](https://aws.amazon.com/blogs/compute/using-github-actions-to-deploy-serverless-applications/);
- [CI/CD для AWS Lambda через GitHub Actions / Хабр](https://habr.com/ru/articles/703416/). alternative variant.

???
