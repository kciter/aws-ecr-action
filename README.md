# AWS ECR Action

This Action allows you to create Docker images and push into a ECR repository.

## Parameters

| Parameter                      | Type      | Default            | Description                                                                                                                                                                               |
| ------------------------------ | --------- | ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `access_key_id`                | `string`  |                    | Your AWS access key id                                                                                                                                                                    |
| `secret_access_key`            | `string`  |                    | Your AWS secret access key                                                                                                                                                                |
| `account_id`                   | `string`  |                    | Your AWS Account ID                                                                                                                                                                       |
| `repo`                         | `string`  |                    | Name of your ECR repository                                                                                                                                                               |
| `region`                       | `string`  |                    | Your AWS region                                                                                                                                                                           |
| `create_repo`                  | `boolean` | `false`            | Set this to true to create the repository if it does not already exist                                                                                                                    |
| `set_repo_policy`              | `boolean` | `false`            | Set this to true to set a IAM policy on the repository                                                                                                                                    |
| `repo_policy_file`             | `string`  | `repo-policy.json` | Set this to repository policy statement json file. only used if the set_repo_policy is set to true                                                                                        |
| `image_scanning_configuration` | `boolean` | `false`            | Set this to True if you want AWS to scan your images for vulnerabilities                                                                                                                  |
| `tags`                         | `string`  | `latest`           | Comma-separated string of ECR image tags (ex latest,1.0.0,)                                                                                                                               |
| `dockerfile`                   | `string`  | `Dockerfile`       | Name of Dockerfile to use                                                                                                                                                                 |
| `docker_image_path`            | `string`  | ``                 | Path to the docker image if build at as a seperate step. If this path is provided docker build is skipped and passed image is uploaded. The tags must be associated with the image built. |
| `extra_build_args`             | `string`  | `""`               | Extra flags to pass to docker build (see docs.docker.com/engine/reference/commandline/build)                                                                                              |
| `cache_from`                   | `string`  | `""`               | Images to use as cache for the docker build (see `--cache-from` argument docs.docker.com/engine/reference/commandline/build)                                                              |
| `path`                         | `string`  | `.`                | Path to Dockerfile, defaults to the working directory                                                                                                                                     |
| `prebuild_script`              | `string`  |                    | Relative path from top-level to script to run before Docker build                                                                                                                         |
| `registry_ids`                 | `string`  |                    | : A comma-delimited list of AWS account IDs that are associated with the ECR registries. If you do not specify a registry, the default ECR registry is assumed                            |

## Usage

### Build the docker image

```yaml
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: docker://ghcr.io/argonautdev/aws-ecr-action:latest
        with:
          access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          account_id: ${{ secrets.AWS_ACCOUNT_ID }}
          repo: docker/repo
          region: ap-northeast-2
          tags: latest,${{ github.sha }}
          create_repo: true
          image_scanning_configuration: true
          set_repo_policy: true
          repo_policy_file: repo-policy.json
```

### Pass the specified docker image

```yaml
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - name: Get Short SHA
        id: get_sha
        run: echo ::set-output name=SHA_SHORT::$(git rev-parse --short HEAD)
      - name: Build Image
        uses: docker/build-push-action@v2
        id: build
        with:
          context: .
          file: ./Dockerfile
          push: false
          tags: ${{ secrets. AWS_ACCOUNT_ID }}.dkr.ecr.us-east-2.amazonaws.com/docker/repo:${{ steps.get_sha.outputs.SHA_SHORT }}
          outputs: type=docker,dest=/tmp/image.tar
      - name: Upload artifact
        uses: actions/upload-artifact@v2
        with:
          name: image
          path: /tmp/image.tar

      - name: Download artifact
        uses: actions/download-artifact@v2
        with:
          name: image
          path: ./tmp

      - name: Push to ecr
        uses: argonautdev/aws-ecr-action@pr-tar-image-support
        id: push_to_ecr
        with:
          access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          account_id: ${{ secrets.AWS_ACCOUNT_ID }}
          repo: docker/repo
          region: us-east-2
          tags: ${{ steps.get_sha.outputs.SHA_SHORT }}
          create_repo: true
          image_scanning_configuration: true
          docker_image_path: ./tmp/image.tar
```

If you don't want to use the latest docker image, you can point to any reference in the repo directly.

```yaml
- uses: argonautdev/aws-ecr-action@master
# or
- uses: argonautdev/aws-ecr-action@v1
# or
- uses: argonautdev/aws-ecr-action@0589ad88c51a1b08fd910361ca847ee2cb708a30
```

## License

The MIT License (MIT)
