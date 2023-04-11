resource "aws_s3_bucket" "resources" {
  bucket = var.endpoint
  force_destroy = true
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.resources.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.default_oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bp" {
  bucket = aws_s3_bucket.resources.id
  policy = data.aws_iam_policy_document.s3_policy.json
}