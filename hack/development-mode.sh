#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/.. 

if [ -z "${MY_GIT_REPO_URL}" ]; then
    if [ -n "${MY_GIT_FORK_REMOTE}" ]; then
        MY_GIT_REPO_URL=$(git ls-remote --get-url $MY_GIT_FORK_REMOTE | sed 's|^git@github.com:|https://github.com/|')
    else
        MY_GIT_REPO_URL=$(git ls-remote --get-url | sed 's|^git@github.com:|https://github.com/|')
    fi
fi
if [ -z "${MY_GIT_BRANCH}" ]; then
    MY_GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

if ! git diff --exit-code --quiet; then
    echo "Changes in working Git working tree, commit them or stash them"
    exit 1
fi

# reset the default repos in the development directory to be the current git repo
# this needs to be pushed to your fork to be seen by argocd
$ROOT/hack/util-set-development-repos.sh $MY_GIT_REPO_URL development $MY_GIT_BRANCH

if ! git diff --exit-code --quiet; then
    git commit -a -m "Development mode, do not merge into main"
    git push -f --set-upstream $MY_GIT_FORK_REMOTE $MY_GIT_BRANCH
fi

#set the local cluster to point to the current git repo and branch and update the path to development
$ROOT/hack/util-update-app-of-apps.sh $MY_GIT_REPO_URL development $MY_GIT_BRANCH

if [ -n "$MY_GITHUB_ORG" ]; then
    $ROOT/hack/util-set-github-org $MY_GITHUB_ORG
fi
