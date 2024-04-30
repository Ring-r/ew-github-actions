# github-actions-experiments

experiments with github actions

## 1. create github repository.
[Understanding GitHub Actions - GitHub Docs](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions). official documentation.

### 1.1. create github repository. using github.io.
default configuration changes:
- repository name: github-actions-experiments;
- description: experiments with github actions;
- add a readme file;

### 1.2. clone repository.
```shell
git clone git@github.com:Ring-r/github-actions-experiments.git
cd github-actions-experiments
```

### 1.3. create location to store github actions.
```shell
mkdir -p .github/workflows
```

## 2. create base (empty) workflow.
instead of using workflow from the guide the simple workflow from github.com is clearer for me (look "Simple workflow" in actions/new).

### 2.1.
```shell
vim .github/workflows/blank.yml
```

### 2.2.
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

### 2.3. commit and push changes. `push` initializes workflow.
```shell
git add --all
git commit -m 'add blank workflow'
git push
```

## 3. create aws (empty) workflow.
[GitHub - aws-actions/configure-aws-credentials: Configure AWS credential environment variables for use in other GitHub Actions.](https://github.com/aws-actions/configure-aws-credentials).

there is using identity provider to connect aws and github.

alternative. [Terraform with GitHub Actions : How to Manage & Scale](https://spacelift.io/blog/github-actions-terraform).
Create an IAM user access key by using AWS Console and store it in GitHub Actions secrets named `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. See the documentation for each action used below for the recommended IAM policies for this IAM user, and best practices on handling the access key credentials.

### 3.2. create identity provider.

[Use IAM roles to connect GitHub Actions to actions in AWS | AWS Security Blog](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/).

#### 3.2.1.
```shell
 aws iam create-open-id-connect-provider --url "https://token.actions.githubusercontent.com" --thumbprint-list "6938fd4d98bab03fa
adb97b34396831e3780aea1" --client-id-list "sts.amazonaws.com"
```

#### 3.2.2.
```shell
vim trustpolicyforGitHubOIDC.json
```

#### 3.2.3.
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "<open_id_connect_provider_arn>"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:sub": "repo: <compeny>/<repository>:ref:refs/heads/<branch>",
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
```

#### 3.2.4.
```shell
aws iam create-role --role-name GitHubAction-AssumeRoleWithAction --assume-role-policy-document file://trustpolicyforGitHubOIDC.json
```

### 3.3.
```shell
vim .github/workflows/aws.yml
```

### 3.4.
```yaml
# This workflow use AWS CLI.

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
      # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
      - uses: actions/checkout@v4

      - name: configure aws credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: ${{ env.AWS_REGION }}
          role-to-assume: arn:aws:iam::592679440475:role/GitHubAction-AssumeRoleWithAction
          role-session-name: samplerolesession

      # Runs a single command using the runners shell
      - name: Run a one-line script
        run: echo Hello, world!

      # Runs a set of commands using the runners shell
      - name: Run a multi-line script
        run: |
          echo Add other actions to build,
          echo test, and deploy your project.
```

### 3.5. commit and push changes. `push` initializes workflow.
```shell
git add --all
git commit -m 'add blank workflow'
git push
```

## 4. create base (empty) terraform configuration.
using aws and terraform workflows from github.com (look "Deploy to Amazon ECS" and "Terraform" in actions/new).

### 4.1.
```shell
vim main.tf
```

### 4.2.
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

### 4.3.
```shell
vim .github/workflows/terraform.yml
```

### 4.4.
```yaml
# This workflow installs the latest Terraform CLI and configures them.
# On pull request events, this workflow will run `terraform init`, `terraform fmt`, and `terraform plan`.
# On push events to the "main" branch, `terraform apply` will be executed.
#
# Documentation for `hashicorp/setup-terraform` is located here: https://github.com/hashicorp/setup-terraform
#


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
    environment: production

    # Use the Bash shell regardless whether the GitHub Actions runner is ubuntu-latest, macos-latest, or windows-latest
    defaults:
      run:
        shell: bash

    steps:
    # Checkout the repository to the GitHub Actions runner
    - name: Checkout
      uses: actions/checkout@v4

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

### 4.5. commit and push changes. `push` initializes workflow.
```shell
git add --all
git commit -m 'add terraform workflow'
git push
```

## 5. create terraform configuration with aws s3 backend.

### 5.1. get or create s3 bucket to store tfstate files. <tfstate_bucket>.

#### 5.1.1. get.
```shell
aws s3 ls | grep -om1 'tfstate-.*'
```

#### 5.1.2. create if not exist.
[Create Terraform pre-requisites for AWS using AWS CLI in 3 easy steps – My Devops Journal](https://skundunotes.com/2021/04/03/create-terraform-pre-requisites-for-aws-using-aws-cli-in-3-easy-steps/).

???

### 5.2. update workflow to use aws.

#### 5.2.1.
```shell
vim .github/workflow/terraform.yml
```

#### 5.2.2.

???

#### 5.2.3. commit and push changes. `push` initializes workflow.
```shell
git add --all
git commit -m 'add aws to workflow'
git push
```

### 5.3. update terraform configuration to use s3 backend.

#### 5.3.1.
```shell
vim main.tf
```

#### 5.3.2.
```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

    backend "s3" {
      bucket = <tfsate_bucket_name_>
      key    = "github-actions-experiments/terraform.tfstate"
      region = "eu-central-1"
    }
}

# An example resource that does nothing.
resource "null_resource" "example" {
  triggers = {
    value = "A example resource that does nothing!"
  }
}
```

Q: should s3 buckend backend name be hidden? should it be moved to secrets or some other github storage?

#### 5.3.3. commit and push changes. `push` initializes workflow.
```shell
git add --all
git commit -m 'add aws to terraform configuration'
git push
```

## ???

???
