#============================================================
# Secrets Manager
#============================================================

# シークレットの作成
resource "aws_secretsmanager_secret" "secret" {
  # シークレット名
  name = "${var.project_name}-lambda-${local.lower_random_hex}"
  # 説明文
  description = "${var.project_name}-lambda-${local.lower_random_hex}"
  # タグ
  tags = {
    Name = var.project_name
  }
}

# シークレット値の設定
resource "aws_secretsmanager_secret_version" "secret" {
  # 格納先のシークレット名の指定
  secret_id = aws_secretsmanager_secret.secret.id
  # シークレット値の設定
  secret_string = jsonencode({
    username = "user"
    password = "password"
  })
}
