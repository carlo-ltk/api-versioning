#!/bin/sh

version=${1:-stable}

echo serving \"$version\" ... "\n"
npm run serverless deploy -- --stage $version
aws ssm put-parameter --name fnd-api-s2-versions --value "$(aws ssm get-parameter --name fnd-api-s2-versions --query "Parameter.Value" --output text  | jq --arg version "$version" '. += [$version] | unique')" --overwrite
terraform -chdir=infra apply --auto-approve


