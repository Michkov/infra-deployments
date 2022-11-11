#!/usr/bin/env bash

PRIVATE_KEY=$(mktemp)
if [ -n "${BUILD_GITHUB_APP_ID}" ] && [ -n "${BUILD_GITHUB_APP_PRIVATE_KEY}" ]; then
  GITHUB_APP_PRIVATE_KEY="$(echo $BUILD_GITHUB_APP_PRIVATE_KEY | base64 -d > $PRIVATE_KEY)"
  GITHUB_APP_DATA="--from-file github-private-key=$PRIVATE_KEY --from-literal github-application-id=${BUILD_GITHUB_APP_ID}"
fi

if [ -n "${BUILD_GITHUB_TOKEN}" ]; then
  GITHUB_WEBHOOK_DATA="--from-literal github.token=${BUILD_GITHUB_TOKEN}"
else
  if [ -n "${MY_GITHUB_TOKEN}" ]; then
    GITHUB_WEBHOOK_DATA="--from-literal github.token=${MY_GITHUB_TOKEN}"
  fi
fi

if [ -n "${BUILD_GITLAB_TOKEN}" ]; then
  GITLAB_WEBHOOK_DATA="--from-literal gitlab.token=${BUILD_GITLAB_TOKEN}"
fi

KUBECONFIG_PARAM=""
if [[ -n ${KCP_KUBECONFIG} ]]
then
  echo $KCP_KUBECONFIG
  KUBECONFIG_PARAM="--kubeconfig ${KCP_KUBECONFIG}"
fi

NAMESPACE='build-service'
SECRET_NAME='pipelines-as-code-secret'
oc -n $NAMESPACE create -o yaml --dry-run=client secret generic $SECRET_NAME $GITHUB_APP_DATA $GITHUB_WEBHOOK_DATA $GITLAB_WEBHOOK_DATA | oc apply -f- $KUBECONFIG_PARAM
rm $PRIVATE_KEY
echo "Configured ${SECRET_NAME} secret in ${NAMESPACE} namespace"
