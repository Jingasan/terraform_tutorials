#============================================================
# Secrets Manager
#============================================================

# Aurora用のシークレットの作成
resource "aws_secretsmanager_secret" "rds" {
  # シークレット名
  name = "${var.project_name}-${var.aurora_engine}-secret"
  # 削除後のシークレット保存期間（日）
  recovery_window_in_days = var.secrets_manager_recovery_window_in_days
  # 説明
  description = "${var.project_name} Aurora ${var.aurora_engine} secret"
  # タグ
  tags = {
    Name              = "${var.project_name}-aurora-postgresql"
    ProjectName       = var.project_name
    ResourceCreatedBy = "terraform"
  }
}

# シークレット値の設定
resource "aws_secretsmanager_secret_version" "rds" {
  # 値の設定先となるシークレットID
  secret_id = aws_secretsmanager_secret.rds.id
  # シークレット値
  secret_string = jsonencode({
    engine               = "${aws_rds_cluster.aurora_postgresql.engine}"
    dbInstanceIdentifier = "${aws_rds_cluster.aurora_postgresql.id}"
    host                 = "${aws_rds_cluster.aurora_postgresql.endpoint}"
    port                 = "${aws_rds_cluster.aurora_postgresql.port}"
    username             = "${aws_rds_cluster.aurora_postgresql.master_username}"
    password             = "${aws_rds_cluster.aurora_postgresql.master_password}"
  })
}

# resource "aws_secretsmanager_secret" "aurora_secret" {
#   name = "aurora-cluster-credentials"
#   description = "Aurora master credentials managed by AWS"
#   rotation_lambda_arn = aws_lambda_function.rotation_lambda.arn
#   rotation_rules {
#     automatically_after_days = 30
#   }
# }
