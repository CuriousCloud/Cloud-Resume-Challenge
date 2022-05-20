###################################
# CloudFront OAI
###################################

resource "aws_cloudfront_origin_access_identity" "cf_oai" {
  comment = "OAI for ${var.endpoint}"
}

###################################
# ACM Cert
###################################

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
}

###################################
# Cert Validation
###################################

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.domain.zone_id
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

###################################
# S3 Bucket
###################################

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = var.bucket_name
  acl    = "private"

  website {
    index_document = "index.html"
  }
}

###################################
# S3 Bucket Public Access Block
###################################

resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

###################################
# S3 Bucket Policy
###################################

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

###################################
# Upload Files to Bucket
###################################

locals {
  mime_types = {
    "css"  = "text/css"
    "html" = "text/html"
    "ico"  = "image/vnd.microsoft.icon"
    "jpeg" = "image/jpeg"
    "js"   = "application/javascript"
    "json" = "application/json"
    "map"  = "application/json"
    "pdf"  = "application/pdf"
    "png"  = "image/png"
    "svg"  = "image/svg+xml"
    "txt"  = "text/plain"
    "doc"  = "document"
  }
}

resource "aws_s3_bucket_object" "frontend_files" {
  for_each = fileset("frontend_files/", "**/*.*")

  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = each.key
  source       = "frontend_files/${each.key}"
  content_type = lookup(tomap(local.mime_types), element(split(".", each.key), length(split(".", each.key)) - 1))
  etag         = filemd5("frontend_files/${each.key}")
}

###################################
# CloudFront Distribution
###################################

resource "aws_cloudfront_distribution" "cf" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = [var.endpoint]

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    forwarded_values {
      headers      = []
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cf_oai.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
}

###################################
# Route 53 Alias Record
###################################

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = var.endpoint
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = true
  }
}
