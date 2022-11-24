#!/bin/sh

version=${1:-stable}

echo serving \"$version\" ... "\n"
npm run serverless deploy -- --stage $version
jq --arg version "$version" '.versions |= (.+[$version] | unique)'  infra/versions.auto.tfvars.json > tmp.$$.json && mv tmp.$$.json infra/versions.auto.tfvars.json
terraform -chdir=infra apply --auto-approve


