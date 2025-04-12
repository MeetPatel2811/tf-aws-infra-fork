resource "random_uuid" "secret_suffix" {}
resource "aws_secretsmanager_secret" "db_password" {
  name        = "csye-password-db-${var.db_name}-${var.domain_name}-${random_uuid.secret_suffix.result}"
  description = "Database password for ${var.db_name} on ${var.domain_name}"
  kms_key_id  = aws_kms_key.secrets_kms.arn

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [name]
  }
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({ password = var.db_password })
}
