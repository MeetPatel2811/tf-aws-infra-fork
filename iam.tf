resource "aws_iam_role" "web_instance_role" {
  name = "${var.name_prefix}-web-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.name_prefix}-s3-policy"
  description = "Policy to allow S3 access for uploading files"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      Effect = "Allow",
      Resource = [
        aws_s3_bucket.s3_bucket.arn,
        "${aws_s3_bucket.s3_bucket.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "web_s3_attach" {
  role       = aws_iam_role.web_instance_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_attach" {
  role       = aws_iam_role.web_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "web_instance_profile" {
  name = "${var.name_prefix}-web-profile"
  role = aws_iam_role.web_instance_role.name
}