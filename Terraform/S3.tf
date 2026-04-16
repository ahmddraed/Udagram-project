resource "aws_s3_bucket" "app_bucket" {
  bucket = "udagram-s3-bucket-ahmddraed-123"
}

resource "aws_iam_role" "fargate_role" { # el role bta3t el api (fargate) 
  name = "fargate-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.app_bucket.id
  policy = <<EOF
        {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_role.fargate_role.arn}"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.app_bucket.id}/*"
            }
        ]
        }
EOF
}


#__________________________________________________________________________________________________
# FRONT-END
#__________________________________________________________________________________________________

resource "aws_s3_bucket" "frontend" {
  bucket = "udagram-frontend-s3"
  force_destroy = true
}

# disable block public access
resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# enable website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document { #3shan yrg3 html 
    key = "index.html"
  }
}

# bucket policy public
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.frontend.id

  depends_on = [
    aws_s3_bucket_public_access_block.allow_public
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}


# optional: output website URL
output "website_url" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}