locals {
  s3_origin_id = "StorageOrigin"
}

resource "aws_cloudfront_origin_access_identity" "default_oai" {
  comment = "Default"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default_oai.cloudfront_access_identity_path
    }

    domain_name              = aws_s3_bucket.resources.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  comment             = "Static node application"
  default_root_object = "index.html"

  aliases = [var.endpoint]

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only" 
  }
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.default_zone.zone_id
  name    = var.endpoint
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}