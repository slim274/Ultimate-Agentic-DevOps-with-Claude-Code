
locals {
  bucket_name = "${var.project_name}-${var.environment}-site"
}

# -------------------------------------------------------------------
# CloudFront Managed Cache Policy (avoid hardcoded UUID)
# -------------------------------------------------------------------
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# -------------------------------------------------------------------
# DynamoDB Table for Terraform State Locking
# -------------------------------------------------------------------
resource "aws_dynamodb_table" "tf_lock" {
  provider     = aws.us_east_1
  name         = "portfolio-site-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = true
  }
}

# -------------------------------------------------------------------
# S3 Bucket (private — no public access)
# -------------------------------------------------------------------
resource "aws_s3_bucket" "site" {
  bucket = local.bucket_name

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -------------------------------------------------------------------
# KMS Key for S3 Encryption (customer-managed, auto-rotates annually)
# -------------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "s3" {
  description             = "CMK for ${var.project_name} S3 buckets"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Non-destructive admin actions available to the account root principal
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:CreateAlias",
          "kms:CreateGrant",
          "kms:DescribeKey",
          "kms:EnableKey",
          "kms:EnableKeyRotation",
          "kms:ListAliases",
          "kms:ListGrants",
          "kms:ListKeyPolicies",
          "kms:ListKeys",
          "kms:ListResourceTags",
          "kms:ListRetirableGrants",
          "kms:UpdateAlias",
          "kms:UpdateKeyDescription",
          "kms:RevokeGrant",
          "kms:RetireGrant",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:GetParametersForImport",
          "kms:DeleteAlias",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        # Destructive key actions require MFA — prevents silent key destruction
        Sid    = "KMSAdminDestructive"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:PutKeyPolicy",
          "kms:ScheduleKeyDeletion",
          "kms:DisableKey",
          "kms:DisableKeyRotation",
          "kms:DeleteImportedKeyMaterial"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      },
      {
        # Scoped to specific buckets to prevent confused-deputy misuse
        Sid    = "AllowS3ServiceUsage"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# -------------------------------------------------------------------
# S3 Server-Side Encryption (SSE-KMS with customer-managed key)
# -------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

# -------------------------------------------------------------------
# CloudFront Origin Access Control (OAC)
# -------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for ${var.project_name} S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -------------------------------------------------------------------
# CloudFront Security Response Headers Policy
# -------------------------------------------------------------------
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "${var.project_name}-${var.environment}-security-headers"
  comment = "Security response headers for ${var.project_name}"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_security_policy {
      # Font Awesome 6.5.0 is loaded from cdnjs.cloudflare.com CDN — allowed in style-src and font-src
      content_security_policy = "default-src 'self'; script-src 'self'; style-src 'self' https://cdnjs.cloudflare.com; img-src 'self' data:; font-src 'self' https://cdnjs.cloudflare.com;"
      override                = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    content_type_options {
      override = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }

  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "camera=(), microphone=(), geolocation=(), payment=()"
      override = true
    }
  }
}

# -------------------------------------------------------------------
# CloudFront Access Logging Bucket
# -------------------------------------------------------------------
resource "aws_s3_bucket" "cf_logs" {
  bucket = "${local.bucket_name}-cf-logs"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "cf_logs" {
  bucket                  = aws_s3_bucket.cf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    id     = "expire-cf-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# -------------------------------------------------------------------
# S3 Server Access Logging for Site Bucket
# -------------------------------------------------------------------
resource "aws_s3_bucket_logging" "site" {
  bucket        = aws_s3_bucket.site.id
  target_bucket = aws_s3_bucket.cf_logs.id
  target_prefix = "s3-access-logs/"
}

# -------------------------------------------------------------------
# WAF WebACL (must be us-east-1 for CloudFront scope)
# NOTE: WAF incurs ~$5/month base cost + per-request charges.
# -------------------------------------------------------------------
resource "aws_wafv2_web_acl" "site" {
  provider    = aws.us_east_1
  name        = "${var.project_name}-${var.environment}-waf"
  scope       = "CLOUDFRONT"
  description = "WAF WebACL for ${var.project_name} CloudFront distribution"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# -------------------------------------------------------------------
# ACM Certificate (us-east-1 required for CloudFront)
# Only created when var.domain_name is set.
# After apply, add the CNAME records output to your DNS provider,
# then re-run terraform apply to complete validation.
# -------------------------------------------------------------------
resource "aws_acm_certificate" "site" {
  count             = var.domain_name != "" ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_acm_certificate_validation" "site" {
  count                   = var.domain_name != "" ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.site[0].arn
  validation_record_fqdns = [for record in aws_acm_certificate.site[0].domain_validation_options : record.resource_record_name]
}

output "acm_validation_records" {
  description = "DNS CNAME records to add to your domain registrar to validate the ACM certificate"
  value = var.domain_name != "" ? [
    for option in aws_acm_certificate.site[0].domain_validation_options : {
      name  = option.resource_record_name
      type  = option.resource_record_type
      value = option.resource_record_value
    }
  ] : []
}

# -------------------------------------------------------------------
# CloudFront Distribution
# -------------------------------------------------------------------
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  default_root_object = "index.html"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  comment             = "${var.project_name} ${var.environment} distribution"

  aliases    = var.domain_name != "" ? [var.domain_name] : []
  web_acl_id = aws_wafv2_web_acl.site.arn

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${local.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id           = "s3-${local.bucket_name}"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  logging_config {
    bucket          = aws_s3_bucket.cf_logs.bucket_domain_name
    prefix          = "cf-access-logs/"
    include_cookies = false
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  restrictions {
    geo_restriction {
      # Intentionally unrestricted — portfolio site has a global audience.
      # To limit to specific countries, change to:
      #   restriction_type = "whitelist"
      #   locations        = ["NG", "IN", "GB", "US"]
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.domain_name != "" ? aws_acm_certificate_validation.site[0].certificate_arn : null
    cloudfront_default_certificate = var.domain_name == ""
    ssl_support_method             = var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# -------------------------------------------------------------------
# S3 Bucket Policy — grant CloudFront OAC read access
# -------------------------------------------------------------------
data "aws_iam_policy_document" "site_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_bucket_policy.json

  depends_on = [aws_s3_bucket_public_access_block.site]
}
