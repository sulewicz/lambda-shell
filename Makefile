ROLE_NAME=lambda-shell-role
LAMBDA_NAME=lambda-shell
SECRET=$(shell cat secret.txt)
ACCOUNT_ID=$(shell aws sts get-caller-identity --query "Account" --output text 2>/dev/null)

.PHONY: help # Generate list of targets with descriptions.
help:
	@grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1\t\2/' | expand -t32

.PHONY: aws-check
aws-check:
ifeq ($(ACCOUNT_ID),)
	@echo "AWS access is not configured! Aborting..." && false
endif

.PHONY: gs-netcat-check
gs-netcat-check:
	@type gs-netcat || (echo "Please install gs-netcat, see README.md for details." && false)

.PHONY: secret-check
secret-check:
ifeq ($(SECRET),)
	@echo "Secret not defined in secret.txt! Run 'make generate-secret' if you want one to be created for you. Aborting..." && false
endif

.PHONY: generate-secret # Generates a secret
generate-secret:
	@gs-netcat -g >secret.txt

.PHONY: build
build:
	@echo "Preparing function package..."
	@rm -rf function.zip
	@zip -j function.zip lambda-shell/*

.PHONY: create-resources # Creates AWS resources required for Lambda function deployment.
create-aws-resources: aws-check build
	@echo "Creating AWS resources..."
	@echo "Creating '${ROLE_NAME}' role..."
	@aws iam create-role --role-name ${ROLE_NAME} --assume-role-policy-document file://iam/trust-policy.json --no-cli-pager
	@echo "Attaching Lambda execution policy to '${ROLE_NAME} role and waiting for it to propagate..."
	@aws iam attach-role-policy --role-name ${ROLE_NAME} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
	@echo "Creating '${LAMBDA_NAME}' function..."
	@while ! aws lambda create-function --function-name ${LAMBDA_NAME} --zip-file fileb://function.zip --handler function.handler --runtime provided --role arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} --timeout 900 --no-cli-pager; do echo "Retrying..."; sleep 2; done
	@echo "Done!"

.PHONY: delete-aws-resources # Deletes AWS resources - use to clean up your lambda Lambda.
delete-aws-resources: aws-check
	@echo "Deleting AWS resources..."
	@echo "Deleting '${LAMBDA_NAME}' function..."
	@aws lambda delete-function --function-name ${LAMBDA_NAME} || true
	@echo "Detaching Lambda execution policy from '${ROLE_NAME} role..."
	@aws iam detach-role-policy --role-name ${ROLE_NAME} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole || true
	@echo "Deleting '${ROLE_NAME}' role..."
	@aws iam delete-role --role-name ${ROLE_NAME} || true
	@echo "Done!"

.PHONY: deploy-lambda-function # Deploys the Lambda function - required to start the shell.
deploy-lambda-function: aws-check build
	@echo "Deploying Lambda function..."
	@aws lambda update-function-code --function-name ${LAMBDA_NAME} --zip-file fileb://function.zip --publish  --no-cli-pager

.PHONY: spawn-lambda-shell # Spawns the lambda shell.
spawn-lambda-shell: aws-check gs-netcat-check secret-check
	@echo "Starting lambda shell! Run 'make open-lambda-shell' to connect to it."
	@aws lambda invoke --function-name ${LAMBDA_NAME} --payload "\"${SECRET}\"" /tmp/${LAMBDA_NAME}.out --no-cli-pager --cli-binary-format raw-in-base64-out 1>&2 2>/dev/null
	@echo "All done!"

.PHONY: open-lambda-shell # Connects to the lambda shell.
open-lambda-shell: gs-netcat-check secret-check
	@echo "Opening lambda shell..."
	@gs-netcat -i -s "${SECRET}"
	@echo "All done!"
