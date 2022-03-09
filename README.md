# AWS ECR Action

This Action allows you to create Docker images and push into a ECR repository.

## Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `access_key_id` | `string` | | Your AWS access key id |
| `secret_access_key` | `string` | | Your AWS secret access key |
| `account_id` | `string` | | Your AWS Account ID |
| `repo` | `string` | | Name of your ECR repository |
| `region` | `string` | | Your AWS region |
| `create_repo` | `boolean` | `false` | Set this to true to create the repository if it does not already exist |
| `set_repo_policy` | `boolean` | `false` | Set this to true to set a IAM policy on the repository |
| `repo_policy_file` | `string` | `repo-policy.json` | Set this to repository policy statement json file. only used if the set_repo_policy is set to true |
| `tags` | `string` | `latest` | Comma-separated string of ECR image tags (ex latest,1.0.0,) |
| `dockerfile` | `string` | `Dockerfile` | Name of Dockerfile to use |
| `extra_build_args` | `string` | `""` | Extra flags to pass to docker build (see docs.docker.com/engine/reference/commandline/build) |
| `path` | `string` | `.` | Path to Dockerfile, defaults to the working directory |
| `prebuild_script` | `string` | | Relative path from top-level to script to run before Docker build |
| `use_buildkit` | `string` | 0 | Use BuildKit to build Docker images. 1 for true, 0 for false |

## Usage

```yaml
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: docker://ghcr.io/kciter/aws-ecr-action:latest
      with:
        access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        account_id: ${{ secrets.AWS_ACCOUNT_ID }}
        repo: docker/repo
        region: ap-northeast-2
        tags: latest,${{ github.sha }}
        create_repo: true
        set_repo_policy: true
        repo_policy_file: repo-policy.json
```

If you don't want to use the latest docker image, you can point to any reference in the repo directly.

```yaml
  - uses: kciter/aws-ecr-action@master
  # or
  - uses: kciter/aws-ecr-action@v2
  # or
  - uses: kciter/aws-ecr-action@0589ad88c51a1b08fd910361ca847ee2cb708a30
```

## Reference
* https://github.com/CircleCI-Public/aws-ecr-orb
* https://github.com/elgohr/Publish-Docker-Github-Action

## License
The MIT License (MIT)
