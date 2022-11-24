#!/bin/sh

version=${1:-stable}

echo forgetting \"$version\" ... "\n"
npm run serverless remove -- --stage $version
jq --arg version "$version" 'del(.versions[] | select (. == $version))'  infra/versions.auto.tfvars.json > tmp.$$.json && mv tmp.$$.json infra/versions.auto.tfvars.json
terraform -chdir=infra apply --auto-approve


