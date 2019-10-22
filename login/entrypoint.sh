#!/bin/sh
set -e

export AWS_ACCESS_KEY_ID=$INPUT_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$INPUT_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$INPUT_REGION

authTokenOutput=$(aws ecr get-authorization-token)
authString=$(echo "$authTokenOutput" | jq -r '.authorizationData[].authorizationToken' | base64 -d)
USERNAME=$(echo "$authString" | cut -d: -f1)
PASSWORD=$(echo "$authString" | cut -d: -f2)
REGISTRY=$(echo "$authTokenOutput" | jq -r '.authorizationData[].proxyEndpoint')

# LOGIN_COMMAND=$(aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION)
# $LOGIN_COMMAND

if [ -z "$USERNAME" ]; then
  USERNAME="AWS"
fi

echo "::set-output name=username::${USERNAME}"
echo "::add-mask::${PASSWORD}"
echo "::set-output name=password::${PASSWORD}"
echo "::set-output name=registry::${REGISTRY}"