#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/.. 

if [ -f $ROOT/hack/development-mode.env ]; then
    source $ROOT/hack/development-mode.env
fi

if [ -z "$MY_GIT_FORK_REMOTE" ]; then
    echo "Set MY_GIT_FORK_REMOTE environment to name of your fork remote"
fi

MY_GIT_REPO_URL=$(git ls-remote --get-url $MY_GIT_FORK_REMOTE | sed 's|^git@github.com:|https://github.com/|')
MY_GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)


if echo "$MY_GIT_REPO_URL" | grep -q https://github.com/redhat-appstudio/infra-deployments; then
    echo "Use your fork repository for development mode"
    exit 1
fi

if ! git diff --exit-code --quiet; then
    echo "Changes in working Git working tree, commit them or stash them"
    exit 1
fi

# Create dev branch for development-mode configuration
DEV_BRANCH=${MY_GIT_BRANCH}-dev
if git rev-parse --verify $DEV_BRANCH; then
    git branch -D $DEV_BRANCH
fi
git checkout -b $DEV_BRANCH

# reset the default repos in the development directory to be the current git repo
# this needs to be pushed to your fork to be seen by argocd
$ROOT/hack/util-set-development-repos.sh $MY_GIT_REPO_URL development $DEV_BRANCH

if [ -n "$MY_GITHUB_ORG" ]; then
    $ROOT/hack/util-set-github-org $MY_GITHUB_ORG
fi

if ! git diff --exit-code --quiet; then
    git commit -a -m "Development mode, do not merge into main"
    git push -f --set-upstream $MY_GIT_FORK_REMOTE $DEV_BRANCH
fi

git checkout $MY_GIT_BRANCH

#set the local cluster to point to the current git repo and branch and update the path to development
$ROOT/hack/util-update-app-of-apps.sh $MY_GIT_REPO_URL development $DEV_BRANCH
