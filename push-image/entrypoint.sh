#!/bin/sh
set -e

export ACCOUNT_URL="$INPUT_ACCOUNT_ID.dkr.ecr.$INPUT_REGION.amazonaws.com"
export REPO=$INPUT_REPO
export TAG=$INPUT_TAG
export CREATE_REPO=$INPUT_CREATE_REPO

if [ $INPUT_CREATE_REPO -eq 1 ]; then
  aws ecr describe-repositories --region $INPUT_REGION --repository-names $REPO > /dev/null 2>&1 || \
    aws ecr create-repository --region $INPUT_REGION --repository-name $REPO
fi

IFS="," read -ra DOCKER_TAGS <<< "$TAG"
for tag in "${DOCKER_TAGS[@]}"; do
  docker push $ACCOUNT_URL/$REPO:${tag}
done