#!/bin/bash
set -e

INPUT_PATH="${INPUT_PATH:-.}"
INPUT_DOCKERFILE="${INPUT_DOCKERFILE:-Dockerfile}"
INPUT_TAGS="${INPUT_TAGS:-latest}"
INPUT_CREATE_REPO="${INPUT_CREATE_REPO:-false}"
INPUT_SET_REPO_POLICY="${INPUT_SET_REPO_POLICY:-false}"
INPUT_REPO_POLICY_FILE="${INPUT_REPO_POLICY_FILE:-repo-policy.json}"
INPUT_IMAGE_SCANNING_CONFIGURATION="${INPUT_IMAGE_SCANNING_CONFIGURATION:-false}"

function main() {
  sanitize "${INPUT_ACCESS_KEY_ID}" "access_key_id"
  sanitize "${INPUT_SECRET_ACCESS_KEY}" "secret_access_key"
  sanitize "${INPUT_REGION}" "region"
  sanitize "${INPUT_ACCOUNT_ID}" "account_id"
  sanitize "${INPUT_REPO}" "repo"

  ACCOUNT_URL="$INPUT_ACCOUNT_ID.dkr.ecr.$INPUT_REGION.amazonaws.com"

  aws_configure
  assume_role
  login
  run_pre_build_script $INPUT_PREBUILD_SCRIPT
  docker_build $INPUT_TAGS $ACCOUNT_URL
  create_ecr_repo $INPUT_CREATE_REPO
  set_ecr_repo_policy $INPUT_SET_REPO_POLICY
  put_image_scanning_configuration $INPUT_IMAGE_SCANNING_CONFIGURATION
  docker_push_to_ecr $INPUT_TAGS $ACCOUNT_URL
}

function sanitize() {
  if [ -z "${1}" ]; then
    >&2 echo "Unable to find the ${2}. Did you set with.${2}?"
    exit 1
  fi
}

function aws_configure() {
  export AWS_ACCESS_KEY_ID=$INPUT_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$INPUT_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$INPUT_REGION
}

function login() {
  echo "== START LOGIN"
  if [ "${INPUT_REGISTRY_IDS}" == "" ]; then
    INPUT_REGISTRY_IDS=$INPUT_ACCOUNT_ID
  fi

  for i in ${INPUT_REGISTRY_IDS//,/ }
  do
    aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $i.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  done

  echo "== FINISHED LOGIN"
}

function assume_role() {
  if [ "${INPUT_ASSUME_ROLE}" != "" ]; then
    sanitize "${INPUT_ASSUME_ROLE}" "assume_role"
    echo "== START ASSUME ROLE"
    ROLE="arn:aws:iam::${INPUT_ACCOUNT_ID}:role/${INPUT_ASSUME_ROLE}"
    CREDENTIALS=$(aws sts assume-role --role-arn ${ROLE} --role-session-name ecrpush --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text)
    read id key token <<< ${CREDENTIALS}
    export AWS_ACCESS_KEY_ID="${id}"
    export AWS_SECRET_ACCESS_KEY="${key}"
    export AWS_SESSION_TOKEN="${token}"
    echo "== FINISHED ASSUME ROLE"
  fi
}

function create_ecr_repo() {
  if [ "${1}" = true ]; then
    echo "== START CREATE REPO"
    echo "== CHECK REPO EXISTS"
    set +e
    output=$(aws ecr describe-repositories --region $AWS_DEFAULT_REGION --repository-names $INPUT_REPO 2>&1)
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      if echo ${output} | grep -q RepositoryNotFoundException; then
        echo "== REPO DOESN'T EXIST, CREATING.."
        aws ecr create-repository --region $AWS_DEFAULT_REGION --repository-name $INPUT_REPO
        echo "== FINISHED CREATE REPO"
      else
        >&2 echo ${output}
        exit $exit_code
      fi
    else
      echo "== REPO EXISTS, SKIPPING CREATION.."
    fi
    set -e
  fi
}

function set_ecr_repo_policy() {
  if [ "${1}" = true ]; then
    echo "== START SET REPO POLICY"
    if [ -f "${INPUT_REPO_POLICY_FILE}" ]; then
      aws ecr set-repository-policy --repository-name $INPUT_REPO --policy-text file://"${INPUT_REPO_POLICY_FILE}"
      echo "== FINISHED SET REPO POLICY"
    else
      echo "== REPO POLICY FILE (${INPUT_REPO_POLICY_FILE}) DOESN'T EXIST. SKIPPING.."
    fi
  fi
}

function put_image_scanning_configuration() {
  if [ "${1}" = true ]; then
      echo "== START SET IMAGE SCANNING CONFIGURATION"
    if [ "${INPUT_IMAGE_SCANNING_CONFIGURATION}" = true ]; then
      aws ecr put-image-scanning-configuration --repository-name $INPUT_REPO --image-scanning-configuration scanOnPush=${INPUT_IMAGE_SCANNING_CONFIGURATION}
      echo "== FINISHED SET IMAGE SCANNING CONFIGURATION"
    fi
  fi
}

function run_pre_build_script() {
  if [ ! -z "${1}" ]; then
    echo "== START PREBUILD SCRIPT"
    chmod a+x $1
    $1
    echo "== FINISHED PREBUILD SCRIPT"
  fi
}

function docker_build() {
  echo "== START DOCKERIZE"
  local TAG=$1
  local docker_tag_args=""
  local DOCKER_TAGS=$(echo "$TAG" | tr "," "\n")
  for tag in $DOCKER_TAGS; do
    docker_tag_args="$docker_tag_args -t $2/$INPUT_REPO:$tag"
  done

  if [ -n "${INPUT_CACHE_FROM}" ]; then
    for i in ${INPUT_CACHE_FROM//,/ }; do
      docker pull $i
    done

    INPUT_EXTRA_BUILD_ARGS="$INPUT_EXTRA_BUILD_ARGS --cache-from=$INPUT_CACHE_FROM"
  fi

  docker build $INPUT_EXTRA_BUILD_ARGS -f $INPUT_DOCKERFILE $docker_tag_args $INPUT_PATH
  echo "== FINISHED DOCKERIZE"
}

function docker_push_to_ecr() {
  echo "== START PUSH TO ECR"
  local TAG=$1
  local DOCKER_TAGS=$(echo "$TAG" | tr "," "\n")
  for tag in $DOCKER_TAGS; do
    docker push $2/$INPUT_REPO:$tag
    echo name=image::$2/$INPUT_REPO:$tag >> $GITHUB_OUTPUT
  done
  echo "== FINISHED PUSH TO ECR"
}

main
