
data "aws_security_group" "selected" {
  vpc_id = aws_vpc.custom_vpc.id

  filter {
    name   = "group-name"
    values = ["allow-tls"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "alb_logs" {
  policy_id = "Policy112233445566"
  statement {
    actions = [
      "s3:PutObject"
    ]
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${var.elb-account-id}:root"]
      type        = "AWS"
    }
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.b.bucket}/customPrefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
    sid = "AWSConsoleStmt"
  }

  statement {
    actions = [
      "s3:PutObject"
    ]
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    condition {
      test     = "StringEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.b.bucket}/customPrefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
    sid = "AWSLogDeliveryWrite"
  }

  statement {
    actions = [
      "s3:GetBucketAcl"
    ]
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.b.bucket}"
    ]
    sid = "AWSLogDeliveryAclCheck"
  }

  version = "2012-10-17"
}


resource "aws_s3_bucket" "b" {
  bucket = "simple-stack-bucket-for-alb-logs"

  force_destroy = true

  tags = {
    costTag = var.cost_tag
  }
}

resource "aws_s3_bucket_acl" "bucket_alb" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "allow_access_from_alb" {
  bucket = aws_s3_bucket.b.id
  policy = data.aws_iam_policy_document.alb_logs.json
}

resource "aws_lb" "alb" {
  name                       = "alb-custom"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.allow_tls.id]
  subnets                    = [aws_subnet.public1.id, aws_subnet.public2.id]
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  access_logs {
    bucket  = aws_s3_bucket.b.bucket
    prefix  = "customPrefix"
    enabled = true
  }

  tags = {
    costTag = var.cost_tag
  }

}

resource "aws_lb_listener" "basic_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2019-08"
  certificate_arn   = var.acm_ssl_arn

  tags = {
    name = "alb-listener"
  }

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Specify a route"
      status_code  = "503"
    }
  }
}
