module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  namespace = "fnd-api"
  name      = "s2"
}

locals {
  apiname          = "fnd-api-s2"
  versions_mapping = { for version in var.versions : version => data.aws_api_gateway_rest_api.api_versions[version].id }
  versions         = var.versions
}

# Pointer to the each versions' API Gateway
data "aws_api_gateway_rest_api" "api_versions" {
  for_each = toset(var.versions)
  name     = "${local.apiname}-${each.key}"
}

# Create CloudFront distribution for this stage
resource "aws_cloudfront_distribution" "cdn" {
  comment         = module.label.id
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  dynamic "origin" {
    for_each = [for v in var.versions : { version = v }]
    content {
      domain_name         = "${data.aws_api_gateway_rest_api.api_versions[origin.value.version].id}.execute-api.us-east-1.amazonaws.com"
      origin_id           = data.aws_api_gateway_rest_api.api_versions[origin.value.version].name
      origin_path         = "/${origin.value.version}"
      connection_attempts = 3
      connection_timeout  = 10
      custom_origin_config {
        http_port                = 80
        https_port               = 443
        origin_keepalive_timeout = 5
        origin_protocol_policy   = "https-only"
        origin_read_timeout      = 30
        origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = data.aws_api_gateway_rest_api.api_versions["stable"].name

    forwarded_values {
      headers      = ["Origin", "Api-Version"]
      query_string = true
      cookies { forward = "none" }
    }

    # no cache for this demo
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.version_router.arn
      include_body = false
    }
  }
}

module "version_router" {
  source      = "transcend-io/lambda-at-edge/aws"
  version     = "0.5.0"
  name        = "${module.label.id}-version_router"
  description = "route the request to the requested api version"
  runtime     = "nodejs16.x"

  s3_artifact_bucket     = aws_s3_bucket.version_router_artifact.id
  file_globs             = ["index.js"]
  plaintext_params       = local.versions_mapping
  lambda_code_source_dir = "${path.module}/../edge"
}

resource "aws_s3_bucket" "version_router_artifact" {
  bucket = "${module.label.id}-edge-lambda-artifact"
}

resource "aws_s3_bucket_versioning" "version_router_artifact_versioning" {
  bucket = aws_s3_bucket.version_router_artifact.id
  versioning_configuration {
    status = "Enabled"
  }
}

provider "aws" {
  region = "us-east-1"
}

# Usage notes at:  https://github.com/cloudposse/terraform-aws-tfstate-backend
module "terraform_state_backend" {
  source  = "cloudposse/tfstate-backend/aws"
  version = "0.38.1"
  context = module.label.context
  name    = "terraform-state"


  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
}

terraform {
  required_version = "~>1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.40.0"
    }
  }
}