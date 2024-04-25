# github-actions-experiments
experiments with github actions

start from [Understanding GitHub Actions - GitHub Docs](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions).

## steps to reproduce

-
create github repository.
default configuration changes:
- repository name: github-actions-experiments;
- description: experiments with github actions;
- add a readme file;

-
```shell
git clone git@github.com:Ring-r/github-actions-experiments.git
cd github-actions-experiments
```

-
```shell
mkdir -p .github/workflows
```

-
instead of using workflow from the guide the simple workflow from github.comi is clearer for me: https://github.com/Ring-r/github-actions-experiments/actions/new.

```shell
vim .github/workflows/blank.yml
```

```yaml
# This is a basic workflow to help you get started with Actions

name: CI

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

-
commit changes.
```shell
git add --all
git commit -m 'add guide workflow'
git push
```
