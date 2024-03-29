#==============================
# CloudWatch Logs
#==============================

# コンテナのログ保存先をCloudWatch Logsに作成
resource "aws_cloudwatch_log_group" "service" {
  # ロググループ名の設定
  name = "/ecs/${var.container_name}-loggroup"
  # タグ
  tags = {
    "Name" = "Terraform検証用"
  }
}
