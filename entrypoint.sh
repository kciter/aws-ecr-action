#!/bin/bash
set -e

INPUT_CREATE_REPO="${INPUT_CREATE_REPO:-false}"
INPUT_SET_REPO_POLICY="${INPUT_SET_REPO_POLICY:-false}"
INPUT_REPO_POLICY_FILE="${INPUT_REPO_POLICY_FILE:-repo-policy.json}"

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
  create_ecr_repo $INPUT_CREATE_REPO
  set_ecr_repo_policy $INPUT_SET_REPO_POLICY
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






main
