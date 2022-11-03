# Lambda Shell

A simple utility that allows you to instantly spawn an ephemeral (living for up to 15 minutes) remote shell in an AWS Lambda function, because why not?

## How to Use

### Prerequisites

You need to have the following:
1. `gs-netcat` binary in your PATH ([instructions](https://github.com/hackerschoice/gsocket/blob/master/deploy/README.md)) required to connect to your ephemeral shell.
1. AWS CLI in your PATH ([instructions](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)) required to spin up and use AWS resources.
1. AWS account in which the resources will be created.
1. AWS credentials configured in your command line (`aws configure`) that grant access to the actions defined in [cli-policy.json](iam/cli-policy.json).

### Managing AWS resources

To create the required resources, run (you may see a couple of retries due to eventual consistency in IAM):
```
make create-aws-resources
```

You can keep the resources in the account if you frequently use the Lambda. However, if you want to clean up the resources, simply run:
```
make delete-aws-resources
```

### Using the shell

First, ensure you've handled the prerequisites and created the necessary AWS resources with `make create-aws-resources` (you may see a couple of retries due to eventual consistency in IAM).

Next, create a secret.txt file in this folder, or simply run `make generate-secret` to have one created for you.

Next, spawn the shell server by running `make spawn-lambda-shell`. To connect to it, run `make open-lambda-shell` in a separate terminal. The gs-netcat shell has rich features; please check the [manual page](https://www.thc.org/gs-netcat.1.html) for details. You can connect to multiple sessions in parallel.

**IMPORTANT:** the shell server won't stop unless the Lambda function times out (after 15 minutes) or you invoke the `./stop-lambda` script which is accessible in the home directory after accessing your ephemeral shell.

## Notices

The Lambda function code includes statically compiled gs-netcat binary, which comes from the fantastic Global Socket project ([gsocket.io](https://www.gsocket.io)).

The binary was pulled from this [url](https://github.com/hackerschoice/binary/raw/4d90b47a0cd65a9c7855db06e73236e413d59d6a/gsocket/bin/gs-netcat_x86_64-alpine.tar.gz) and has the following checksum:

```
shasum -a 1 gs-netcat_x86_64-alpine.tar.gz
f54137b99396f907ced135b841fc243e7d26d7b9  gs-netcat_x86_64-alpine.tar.gz
tar xzvf gs-netcat_x86_64-alpine.tar.gz
shasum -a 1 gs-netcat
08676bfd219d150ed8dcc6a1e64027870ab07b2a  gs-netcat
```
