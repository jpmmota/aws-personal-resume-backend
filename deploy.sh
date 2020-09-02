#!/bin/bash

# exit when any command fails
set -e

S3_BUCKET=jpmmota-personal-resume
STACK_NAME=personal-resume-stack
AWS_REGION=ca-central-1
TABLE_NAME=Visits

# delete stack if necessary
echo 'Delete stack...'
aws cloudformation delete-stack --stack-name $STACK_NAME

# echo 'Create s3 bucket...'
# aws s3api create-bucket --bucket $S3_BUCKET --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION

echo 'Build Lambda function...'
sam build --template lambda-dependency-sam.yml --manifest ./lambda/requirements.txt
echo 'Test Lambda function...'
sam local invoke --event ./lambda/test1.json
echo 'Package Lambda function...'
sam package --template-file .aws-sam/build/template.yaml --s3-bucket $S3_BUCKET --output-template-file packaged-lambda-dependency.yml
echo 'Deploy Lambda function...'
sam deploy --template-file packaged-lambda-dependency.yml --stack-name $STACK_NAME --s3-bucket $S3_BUCKET --no-confirm-changeset

aws dynamodb put-item --table-name $TABLE_NAME --item '{ "siteName": { "S": "resume" }, "totalVisits": {"N": "0"} }'

# get API endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[0].OutputValue')

# remove quotes
API_ENDPOINT=$(sed -e 's/^"//' -e 's/"$//' <<< $API_ENDPOINT)

# format output
API_URI=visits/store
# echo $API_URI
API_ENDPOINT=$API_ENDPOINT$API_URI

# echo "Test in browser: $API_ENDPOINT"

# call frontend deploy
echo 'Update frontend API endpoint...'
cd ../frontend
./deploy.sh $API_ENDPOINT