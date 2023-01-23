
module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  namespace = "fnd-api-serveless"
  name      = "ci"
}

locals {
  apiname  = "fnd-api-s2"
  versions = jsondecode(nonsensitive(aws_ssm_parameter.versions.value))
  stages   = [for v in local.versions : v.stage]
}

#npm run terraform -- import aws_ssm_parameter.versions fnd-api-s2-versions
resource "aws_ssm_parameter" "versions" {
  name           = "fnd-api-s2-versions"
  tags           = module.label.tags
  type           = "String"
  insecure_value = "[ { \"tag\": \"stable\", \"stage\": \"stable\" } ]"

  lifecycle {
    ignore_changes = [insecure_value, value, tags]
  }
}

# Pointer to the each versions' API Gateway
data "aws_api_gateway_rest_api" "api_versions" {
  for_each = toset(local.stages)
  name     = "${local.apiname}-${each.key}"
}

#  npm run terraform import aws_cloudfront_distribution.cdn E37HLT8JUFPLNN
resource "aws_cloudfront_distribution" "cdn" {

  # The CloudFront distribution is a resource managed by both this terraform project 
  # and the one in ./parent folder. While is generally not a good practice having 
  # two projects managing the same resource, each project manages different set of attributes.
  #
  # This proejct takes only of the origins that are added or removed in the github workflows that deploy or remove api versions
  lifecycle {
    ignore_changes = [comment, enabled, tags, is_ipv6_enabled, price_class, restrictions, viewer_certificate, default_cache_behavior]
  }

  enabled = true

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
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
  }

  dynamic "origin" {
    for_each = [for s in local.stages : { stage = s }]
    content {
      domain_name         = "${data.aws_api_gateway_rest_api.api_versions[origin.value.stage].id}.execute-api.us-east-1.amazonaws.com"
      origin_id           = data.aws_api_gateway_rest_api.api_versions[origin.value.stage].name
      origin_path         = "/${origin.value.stage}"
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
}

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