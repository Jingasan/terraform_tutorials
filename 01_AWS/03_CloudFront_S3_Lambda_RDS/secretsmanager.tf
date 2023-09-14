#============================================================
# Secrets Manager
#============================================================

# RDS用のSecretの作成
resource "aws_secretsmanager_secret" "rds" {
  # Secret名
  name = "${var.project_name}-${aws_db_instance.rds.engine}-secret"
  # 削除後のシークレット保存期間（日）
  recovery_window_in_days = var.secret_manager_recovery_window_in_days
  # 説明
  description = "${var.project_name} RDS ${aws_db_instance.rds.engine} secret"
  # タグ
  tags = {
    Name = "${var.project_name} RDS ${aws_db_instance.rds.engine} secret"
  }
}

# シークレット値の設定
resource "aws_secretsmanager_secret_version" "rds" {
  # 値の設定先となるシークレットID
  secret_id = aws_secretsmanager_secret.rds.id
  # シークレット値
  secret_string = jsonencode({
    engine               = "${aws_db_instance.rds.engine}"
    dbInstanceIdentifier = "${aws_db_instance.rds.identifier}"
    host                 = "${aws_db_instance.rds.address}"
    port                 = aws_db_instance.rds.port
    username             = "${aws_db_instance.rds.username}"
    password             = "${aws_db_instance.rds.password}"
  })
}
