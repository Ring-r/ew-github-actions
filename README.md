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
```shell
vim .github/workflows/learn-github-actions.yml
```

-
copy code from guide, insert, save.

-
commit changes.
```shell
git add --all
git commit -m 'add guide workflow'
git push
```
