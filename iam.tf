# --- EC2 Role and Instance Profile ---
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

resource "aws_iam_instance_profile" "web_instance_profile" {
  name = "${var.name_prefix}-web-profile"
  role = aws_iam_role.web_instance_role.name
}

# --- Policy: S3 access for the application ---

resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.name_prefix}-s3-policy"
  description = "Policy to allow S3 access for uploading files"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = var.s3_actions,
      Effect = "Allow",
      Resource = [
        aws_s3_bucket.s3_bucket.arn,
        "${aws_s3_bucket.s3_bucket.arn}/*"
      ]
    }]
  })
}

# --- Policy: Infrastructure (ALB, ASG, EC2, KMS, Secrets Manager) ---

resource "aws_iam_policy" "infrastructure_policy" {
  name        = "${var.name_prefix}-infrastructure-policy"
  description = "Policy for infrastructure access (ALB, ASG, KMS, Secrets)"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = var.infrastructure_actions,
        Resource = "*"
      }
    ]
  })
}

# --- Attach Policies to EC2 Role ---

resource "aws_iam_role_policy_attachment" "web_s3_attach" {
  role       = aws_iam_role.web_instance_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_attach" {
  role       = aws_iam_role.web_instance_role.name
  policy_arn = var.cloudwatch_agent_managed_policy_arn
}

resource "aws_iam_role_policy_attachment" "infrastructure_policy_attach" {
  role       = aws_iam_role.web_instance_role.name
  policy_arn = aws_iam_policy.infrastructure_policy.arn
}

# --- ✅ NEW: IAM Policy for Terraform IAM User to Create KMS & Secrets ---

resource "aws_iam_policy" "terraform_kms_creator" {
  name        = "${var.name_prefix}-terraform-kms-access"
  description = "Allows Terraform user to create/manage KMS keys and Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = concat(var.terraform_kms_secret_actions, ["acm:ImportCertificate"])
        Resource = "*"
      }
    ]
  })
}

# --- ✅ Attach to Terraform IAM User (e.g., 'demo') ---

resource "aws_iam_user_policy_attachment" "terraform_user_kms_secrets_access" {
  user       = var.terraform_iam_user
  policy_arn = aws_iam_policy.terraform_kms_creator.arn
}
# --- IAM Group for Terraform users ---
resource "aws_iam_group" "terraform_group" {
  name = "terraform-group"
}

# Attach KMS + Secrets Manager permissions to the group
resource "aws_iam_group_policy_attachment" "group_kms_attach" {
  group      = aws_iam_group.terraform_group.name
  policy_arn = aws_iam_policy.terraform_kms_creator.arn
}
resource "aws_iam_user_group_membership" "terraform_user_group_membership" {
  user   = var.terraform_iam_user
  groups = [aws_iam_group.terraform_group.name]
}


resource "aws_iam_policy" "acm_import_policy" {
  name        = "ACMImportCertificatePolicy"
  description = "Allows importing SSL certificates into ACM"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "acm:ImportCertificate"
        ],
        Resource = "arn:aws:acm:${var.region}:${var.account_id}:certificate/*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "group_acm_import_attach" {
  group      = aws_iam_group.terraform_group.name
  policy_arn = aws_iam_policy.acm_import_policy.arn
}
