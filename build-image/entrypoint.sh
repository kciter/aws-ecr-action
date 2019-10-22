#!/bin/sh
set -e

export ACCOUNT_URL="$INPUT_ACCOUNT_ID.dkr.ecr.$INPUT_REGION.amazonaws.com"
export REPO=$INPUT_REPO
export DOCKERFILE=$INPUT_DOCKERFILE
export EXTRA_BUILD_ARGS=$INPUT_EXTRA_BUILD_ARGS
export PATH=$INPUT_PATH
export TAG=$INPUT_TAG

docker_tag_args=""
IFS="," read -ra DOCKER_TAGS <<< "$TAG"
for tag in "${DOCKER_TAGS[@]}"; do
  docker_tag_args="$docker_tag_args -t $ACCOUNT_URL/$REPO:$tag"
done

docker build $EXTRA_BUILD_ARGS -f $DOCKERFILE $docker_tag_args $PATH
